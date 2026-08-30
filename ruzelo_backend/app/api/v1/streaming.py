import urllib.parse
from typing import Optional
import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, Response, status
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.track import Track
from app.services.audio_streamer import AudioStreamerService

router = APIRouter(tags=["Streaming"])


@router.api_route("/streaming/proxy", methods=["GET", "HEAD", "OPTIONS"])
async def proxy_audio_stream(
    request: Request,
    url: str = Query(..., description="External audio stream URL to proxy"),
    range: Optional[str] = Header(None),
):
    """Proxies external CDN audio streams with full HTTP Byte-Range support and CORS headers for browser audio playback."""
    decoded_url = urllib.parse.unquote(url)

    if request.method == "OPTIONS":
        return Response(
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Expose-Headers": "Content-Range, Accept-Ranges, Content-Length, Content-Type",
            },
        )

    req_headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    }
    if range:
        req_headers["Range"] = range

    client = httpx.AsyncClient(timeout=20.0, follow_redirects=True)
    req = client.build_request("GET" if request.method != "HEAD" else "HEAD", decoded_url, headers=req_headers)
    resp = await client.send(req, stream=True)

    response_headers = {
        "Content-Type": resp.headers.get("content-type", "audio/mp4"),
        "Accept-Ranges": "bytes",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Expose-Headers": "Content-Range, Accept-Ranges, Content-Length, Content-Type",
    }
    if "content-range" in resp.headers:
        response_headers["Content-Range"] = resp.headers["content-range"]
    if "content-length" in resp.headers:
        response_headers["Content-Length"] = resp.headers["content-length"]

    if request.method == "HEAD":
        await resp.aclose()
        await client.aclose()
        return Response(status_code=resp.status_code, headers=response_headers)

    async def stream_generator():
        try:
            async for chunk in resp.aiter_bytes(chunk_size=65536):
                yield chunk
        finally:
            await resp.aclose()
            await client.aclose()

    return StreamingResponse(
        stream_generator(),
        status_code=resp.status_code,
        headers=response_headers,
        media_type=response_headers["Content-Type"],
    )


@router.get("/tracks/{track_id}/stream")
@router.get("/streaming/{track_id}")
async def stream_track_audio(
    track_id: str,
    range: Optional[str] = Header(None),
    ticket: Optional[str] = Query(None, description="Signed stream ticket authorization"),
    db: AsyncSession = Depends(get_db),
):
    """Streams audio chunks with 128KB buffering and HTTP Byte-Range seekable streaming."""
    stmt = select(Track).where(Track.id == track_id)
    result = await db.execute(stmt)
    track = result.scalar_one_or_none()

    if not track:
        # Check if file exists directly on disk
        import os
        for ext in ["flac", "mp3", "wav"]:
            cand = f"./media/audio/{track_id}.{ext}"
            if os.path.exists(cand):
                return await AudioStreamerService.create_byte_range_response(
                    file_path=cand,
                    range_header=range,
                    format_hint=ext,
                    track_id=track_id,
                )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Track with ID '{track_id}' not found",
        )

    # Increment play count asynchronously
    track.play_count += 1
    await db.commit()

    file_path = track.audio_file_path or f"./media/audio/{track.id}.{track.format}"
    return await AudioStreamerService.create_byte_range_response(
        file_path=file_path,
        range_header=range,
        format_hint=track.format,
        stream_ticket=ticket,
        track_id=track.id,
    )
