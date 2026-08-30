from typing import Optional
from sqlalchemy import Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Track(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "tracks"

    title: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    artist: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    artist_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True, index=True)
    album: Mapped[str] = mapped_column(String(255), nullable=False, default="Single")
    duration_seconds: Mapped[int] = mapped_column(Integer, nullable=False, default=180)
    
    # Media paths, Format & Bitrate
    audio_file_path: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    format: Mapped[str] = mapped_column(String(16), nullable=False, default="flac")  # "mp3" or "flac"
    bitrate_kbps: Mapped[int] = mapped_column(Integer, nullable=False, default=1411)
    sample_rate_hz: Mapped[int] = mapped_column(Integer, nullable=False, default=44100)
    
    cover_art_url: Mapped[str] = mapped_column(
        String(512),
        nullable=False,
        default="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800",
    )
    
    # Acoustic & Mood Classification
    genre: Mapped[str] = mapped_column(String(64), nullable=False, default="Electronic", index=True)
    bpm: Mapped[float] = mapped_column(Float, nullable=False, default=120.0)
    energy: Mapped[float] = mapped_column(Float, nullable=False, default=0.75)
    valence: Mapped[float] = mapped_column(Float, nullable=False, default=0.65)
    danceability: Mapped[float] = mapped_column(Float, nullable=False, default=0.70)
    acousticness: Mapped[float] = mapped_column(Float, nullable=False, default=0.25)
    mood_tags: Mapped[str] = mapped_column(String(255), nullable=False, default="atmospheric,euphoric")
    play_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
