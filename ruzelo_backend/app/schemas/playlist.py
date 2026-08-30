from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.track import TrackRead


class PlaylistBase(BaseModel):
    title: str
    description: str = ""
    cover_image_url: str = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800"
    atmosphere_tag: str = "Cyber Aura"
    is_public: bool = True


class PlaylistCreate(PlaylistBase):
    track_ids: Optional[List[str]] = []


class PlaylistUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    atmosphere_tag: Optional[str] = None
    is_public: Optional[bool] = None


class PlaylistAddTrack(BaseModel):
    track_id: str


class PlaylistRead(PlaylistBase):
    id: str
    user_id: str
    tracks: List[TrackRead] = []
    track_count: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
