from typing import List, Optional
from sqlalchemy import Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Artist(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "artists"

    name: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    bio: Mapped[str] = mapped_column(Text, nullable=False, default="")
    image_url: Mapped[str] = mapped_column(
        String(512),
        nullable=False,
        default="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800",
    )
    banner_url: Mapped[str] = mapped_column(
        String(512),
        nullable=False,
        default="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200",
    )
    monthly_listeners: Mapped[int] = mapped_column(Integer, nullable=False, default=1500000)
    genre: Mapped[str] = mapped_column(String(64), nullable=False, default="Electronic")
