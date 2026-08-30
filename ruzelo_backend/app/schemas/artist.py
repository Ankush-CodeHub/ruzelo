from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.track import TrackRead


class ArtistBase(BaseModel):
    name: str
    bio: str = ""
    image_url: str
    banner_url: str
    monthly_listeners: int = 1000000
    genre: str = "Electronic"


class ArtistCreate(ArtistBase):
    pass


class ArtistRead(ArtistBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ArtistDetail(ArtistRead):
    top_tracks: List[TrackRead] = []
