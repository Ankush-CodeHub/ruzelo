from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    tier: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class StreamTicketResponse(BaseModel):
    ticket: str
    stream_url: str
    expires_in: int


class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    preferred_atmosphere: Optional[str] = "cyber_aura"


class UserLogin(BaseModel):
    username: str
    password: str


class UserProfile(BaseModel):
    id: str
    username: str
    email: str
    tier: str
    preferred_atmosphere: str
    created_at: datetime


class TierUpgradeRequest(BaseModel):
    tier: str = "infinite"  # "free" or "infinite"
