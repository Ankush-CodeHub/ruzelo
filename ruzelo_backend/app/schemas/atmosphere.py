from datetime import datetime
from typing import List, Optional, Tuple
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.track import TrackRead


class AtmosphereBase(BaseModel):
    name: str
    description: str
    primary_color: str = "#8B5CF6"
    secondary_color: str = "#06B6D4"
    accent_color: str = "#EC4899"
    shader_speed: float = 1.0
    noise_scale: float = 1.0
    audio_reactive_factor: float = 1.0


class AtmosphereCreate(AtmosphereBase):
    pass


class AtmosphereUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    accent_color: Optional[str] = None
    shader_speed: Optional[float] = None
    noise_scale: Optional[float] = None
    audio_reactive_factor: Optional[float] = None


class AtmosphereRead(AtmosphereBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ShaderUniformsResponse(BaseModel):
    atmosphere_id: str
    name: str
    color_a_rgb: Tuple[float, float, float]
    color_b_rgb: Tuple[float, float, float]
    color_c_rgb: Tuple[float, float, float]
    speed: float
    noise_scale: float
    reactive_factor: float


class AtmosphereRecommendationRequest(BaseModel):
    energy_level: float = Field(0.70, ge=0.0, le=1.0, description="User energy slider from 0.0 (Chill) to 1.0 (Euphoric/Overdrive)")
    time_of_day: Optional[str] = Field(None, description="e.g. 'Morning', 'Afternoon', 'Golden Hour', 'Midnight'")
    atmosphere_tag: Optional[str] = Field(None, description="e.g. 'Cyber Aura', 'Midnight Velvet', 'Sunset Nebula', 'Deep Zen'")
    limit: int = Field(10, ge=1, le=50)


class AtmosphereRecommendationResponse(BaseModel):
    atmosphere: AtmosphereRead
    energy_level: float
    time_of_day: str
    curated_tracks: List[TrackRead]
