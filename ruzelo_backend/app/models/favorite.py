from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Favorite(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "favorites"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    track_id: Mapped[str] = mapped_column(String(36), ForeignKey("tracks.id", ondelete="CASCADE"), nullable=False, index=True)


class PlayHistory(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "play_history"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    track_id: Mapped[str] = mapped_column(String(36), ForeignKey("tracks.id", ondelete="CASCADE"), nullable=False, index=True)
    atmosphere_id: Mapped[str] = mapped_column(String(64), nullable=False, default="cyber_aura")
