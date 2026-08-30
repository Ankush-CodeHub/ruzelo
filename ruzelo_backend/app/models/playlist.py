from typing import List, Optional
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Table, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

# Association table for playlist tracks
playlist_tracks = Table(
    "playlist_tracks",
    Base.metadata,
    Column("playlist_id", String(36), ForeignKey("playlists.id", ondelete="CASCADE"), primary_key=True),
    Column("track_id", String(36), ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True),
    Column("position", Integer, default=0),
)


class Playlist(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "playlists"

    title: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    cover_image_url: Mapped[str] = mapped_column(
        String(512),
        nullable=False,
        default="https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800",
    )
    atmosphere_tag: Mapped[str] = mapped_column(String(64), nullable=False, default="Cyber Aura")
    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    is_public: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
