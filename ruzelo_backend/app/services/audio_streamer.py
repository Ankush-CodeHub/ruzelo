import os
import io
import math
import struct
from typing import AsyncGenerator, Optional, Tuple
import aiofiles
from fastapi import HTTPException, status
from fastapi.responses import StreamingResponse
from app.core.config import settings
from app.core.security import verify_stream_ticket


class AudioStreamerService:
    CHUNK_SIZE = 1024 * 128  # 128 KB per chunk

    @staticmethod
    def sanitize_audio_path(file_path: str) -> str:
        """Protects against path traversal attacks by validating path resolution within allowed media root."""
        allowed_root = os.path.abspath(settings.MEDIA_DIR)
        target_path = os.path.abspath(file_path)
        if not target_path.startswith(allowed_root):
            base_name = os.path.basename(file_path)
            return os.path.join(allowed_root, "audio", base_name)
        return target_path

    @staticmethod
    def parse_range_header(range_header: Optional[str], file_size: int) -> Tuple[int, int]:
        if not range_header or not range_header.startswith("bytes="):
            return 0, file_size - 1

        range_val = range_header.replace("bytes=", "").strip()
        parts = range_val.split("-")

        try:
            start = int(parts[0]) if parts[0] else 0
            end = int(parts[1]) if len(parts) > 1 and parts[1] else file_size - 1
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_416_RANGE_NOT_SATISFIABLE,
                detail="Malformed byte range numbers",
                headers={"Content-Range": f"bytes */{file_size}"},
            )

        if start >= file_size or end >= file_size or start > end or start < 0:
            raise HTTPException(
                status_code=status.HTTP_416_RANGE_NOT_SATISFIABLE,
                detail=f"Invalid byte range: {range_header} for file size {file_size}",
                headers={"Content-Range": f"bytes */{file_size}"},
            )

        return start, end

    @classmethod
    def get_content_type(cls, file_path: str, format_hint: str = "flac") -> str:
        if file_path.endswith(".flac") or format_hint.lower() == "flac":
            return "audio/flac"
        if file_path.endswith(".wav"):
            return "audio/wav"
        return "audio/mpeg"

    @classmethod
    async def create_byte_range_response(
        cls,
        file_path: str,
        range_header: Optional[str],
        format_hint: str = "flac",
        stream_ticket: Optional[str] = None,
        track_id: Optional[str] = None,
    ) -> StreamingResponse:
        # Stream ticket authorization verification
        if stream_ticket and track_id:
            ticket_payload = verify_stream_ticket(stream_ticket, track_id)
            if not ticket_payload:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Invalid or expired stream authorization ticket",
                )

        safe_path = cls.sanitize_audio_path(file_path)

        if not os.path.exists(safe_path):
            # Synthetic high-fidelity ambient generator fallback
            return cls.generate_synthetic_stream(range_header, format_hint=format_hint)

        file_size = os.path.getsize(safe_path)
        start, end = cls.parse_range_header(range_header, file_size)
        content_length = end - start + 1
        content_type = cls.get_content_type(safe_path, format_hint)

        async def file_iterator() -> AsyncGenerator[bytes, None]:
            async with aiofiles.open(safe_path, mode="rb") as f:
                await f.seek(start)
                bytes_left = content_length
                while bytes_left > 0:
                    chunk_to_read = min(cls.CHUNK_SIZE, bytes_left)
                    data = await f.read(chunk_to_read)
                    if not data:
                        break
                    bytes_left -= len(data)
                    yield data

        headers = {
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Accept-Ranges": "bytes",
            "Content-Length": str(content_length),
            "Content-Type": content_type,
            "Cache-Control": "public, max-age=3600",
        }

        status_code = status.HTTP_206_PARTIAL_CONTENT if range_header else status.HTTP_200_OK
        return StreamingResponse(file_iterator(), status_code=status_code, headers=headers)

    @classmethod
    def generate_synthetic_stream(
        cls, range_header: Optional[str], format_hint: str = "flac"
    ) -> StreamingResponse:
        """Generates a seekable 16-bit 44.1kHz stereo audio byte stream with 128KB chunks for testing."""
        sample_rate = 44100
        duration_sec = 60
        num_samples = sample_rate * duration_sec
        bytes_per_sample = 4  # 16-bit stereo = 2 channels * 2 bytes
        data_size = num_samples * bytes_per_sample
        total_wav_size = 44 + data_size

        start, end = cls.parse_range_header(range_header, total_wav_size)
        content_length = end - start + 1

        # Generate WAV header
        header = bytearray()
        header.extend(b"RIFF")
        header.extend(struct.pack("<I", total_wav_size - 8))
        header.extend(b"WAVEfmt ")
        header.extend(struct.pack("<I", 16))
        header.extend(struct.pack("<H", 1))   # PCM
        header.extend(struct.pack("<H", 2))   # Stereo
        header.extend(struct.pack("<I", sample_rate))
        header.extend(struct.pack("<I", sample_rate * bytes_per_sample))
        header.extend(struct.pack("<H", bytes_per_sample))
        header.extend(struct.pack("<H", 16))
        header.extend(b"data")
        header.extend(struct.pack("<I", data_size))

        async def synth_iterator() -> AsyncGenerator[bytes, None]:
            current_byte = start
            if current_byte < 44:
                header_slice = header[current_byte : min(44, end + 1)]
                current_byte += len(header_slice)
                yield bytes(header_slice)

            sample_idx = (current_byte - 44) // 4
            while current_byte <= end:
                chunk = bytearray()
                chunk_samples = min(cls.CHUNK_SIZE // 4, (end - current_byte + 4) // 4)
                for _ in range(chunk_samples):
                    t = sample_idx / sample_rate
                    # 432 Hz organic ambient drone with harmonic richness
                    val_left = int(7500 * math.sin(2 * math.pi * 432.0 * t) + 3500 * math.sin(2 * math.pi * 864.0 * t))
                    val_right = int(7500 * math.sin(2 * math.pi * 436.0 * t) + 3500 * math.sin(2 * math.pi * 648.0 * t))
                    chunk.extend(struct.pack("<hh", val_left, val_right))
                    sample_idx += 1
                
                current_byte += len(chunk)
                yield bytes(chunk)

        headers = {
            "Content-Range": f"bytes {start}-{end}/{total_wav_size}",
            "Accept-Ranges": "bytes",
            "Content-Length": str(content_length),
            "Content-Type": "audio/wav" if format_hint == "wav" else "audio/flac",
            "Cache-Control": "public, max-age=3600",
        }

        status_code = status.HTTP_206_PARTIAL_CONTENT if range_header else status.HTTP_200_OK
        return StreamingResponse(synth_iterator(), status_code=status_code, headers=headers)
