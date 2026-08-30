from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class TrackBase(BaseModel):
    title: str
    artist: str
    album: str = "Single"
    duration_seconds: int = 180
    cover_art_url: str
    genre: str = "Electronic"
    bpm: float = 120.0
    energy: float = 0.75
    valence: float = 0.65
    danceability: float = 0.70
    mood_tags: str = "atmospheric,euphoric"


class TrackCreate(TrackBase):
    audio_file_path: Optional[str] = None


class TrackUpdate(BaseModel):
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    cover_art_url: Optional[str] = None
    genre: Optional[str] = None
    bpm: Optional[float] = None
    energy: Optional[float] = None


class TrackRead(TrackBase):
    id: str
    play_count: int
    created_at: datetime
    updated_at: datetime
    stream_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class TrackListResponse(BaseModel):
    items: List[TrackRead]
    total: int
    page: int
    page_size: int


class AudioFeaturesVector(BaseModel):
    bpm: float
    energy: float
    valence: float
    danceability: float
