import base64
from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.services.ingestion_service import MusicIngestionService

router = APIRouter(prefix="/ingestion", tags=["Automated Ingestion & Release Radar"])


class DDEXBatchTrack(BaseModel):
    title: str
    artist_name: str
    album: Optional[str] = None
    genre: Optional[str] = "Bollywood"
    cover_art_url: Optional[str] = None
    mood_tags: Optional[str] = "new_release,radar"
    audio_base64: Optional[str] = None


class DDEXBatchRequest(BaseModel):
    distributor_name: str
    batch_reference: str
    tracks: List[DDEXBatchTrack]


@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_and_ingest_track(
    title: str = Form(...),
    artist: str = Form(...),
    album: Optional[str] = Form(None),
    genre: Optional[str] = Form("Bollywood"),
    cover_art_url: Optional[str] = Form(None),
    mood_tags: Optional[str] = Form("new,release_radar,flac"),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    """Uploads a master audio file (FLAC, WAV, MP3), executes automated DSP analysis,
    calculates EBU R128 LUFS loudness, detects BPM, extracts acoustic vectors,
    generates an ISRC, and indexes the track into the live catalog."""
    audio_bytes = await file.read()
    if len(audio_bytes) < 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded audio file is empty or corrupted",
        )

    format_hint = "flac" if file.filename and file.filename.endswith(".flac") else "mp3"
    result = await MusicIngestionService.process_track_upload(
        session=db,
        audio_bytes=audio_bytes,
        title=title,
        artist_name=artist,
        album=album,
        genre=genre,
        cover_art_url=cover_art_url,
        mood_tags=mood_tags,
        format_hint=format_hint,
    )
    return result


@router.post("/ddex-batch", status_code=status.HTTP_201_CREATED)
async def batch_ingest_ddex(
    payload: DDEXBatchRequest,
    db: AsyncSession = Depends(get_db),
):
    """Simulates enterprise DDEX ERN batch delivery from music distributors (Universal, Sony, Warner, DistroKid)."""
    ingested_tracks = []
    for item in payload.tracks:
        if item.audio_base64:
            audio_bytes = base64.b64decode(item.audio_base64)
        else:
            # Generate valid PCM bytes for simulation
            audio_bytes = b"RIFF" + b"\x00" * 40 + b"WAVEfmt " + b"\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x10\x00data" + b"\x00" * 88200

        result = await MusicIngestionService.process_track_upload(
            session=db,
            audio_bytes=audio_bytes,
            title=item.title,
            artist_name=item.artist_name,
            album=item.album,
            genre=item.genre,
            cover_art_url=item.cover_art_url,
            mood_tags=item.mood_tags,
        )
        ingested_tracks.append(result)

    return {
        "distributor": payload.distributor_name,
        "batch_reference": payload.batch_reference,
        "ingested_count": len(ingested_tracks),
        "tracks": ingested_tracks,
    }
