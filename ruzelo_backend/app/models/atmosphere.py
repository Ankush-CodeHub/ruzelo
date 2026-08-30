from sqlalchemy import Float, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Atmosphere(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "atmospheres"

    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False, default="")
    
    # Hex Color Codes for GLSL Uniforms
    primary_color: Mapped[str] = mapped_column(String(9), nullable=False, default="#8B5CF6")
    secondary_color: Mapped[str] = mapped_column(String(9), nullable=False, default="#06B6D4")
    accent_color: Mapped[str] = mapped_column(String(9), nullable=False, default="#EC4899")
    
    # Shader Dynamic Parameters
    shader_speed: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    noise_scale: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
    audio_reactive_factor: Mapped[float] = mapped_column(Float, nullable=False, default=1.0)
