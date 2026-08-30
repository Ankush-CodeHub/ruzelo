from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Ruzelo API"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    
    # Security & Tokens
    SECRET_KEY: str = "ruzelo_super_secret_jwt_encryption_key_2026_atmosphere"
    REFRESH_SECRET_KEY: str = "ruzelo_super_secret_refresh_token_key_2026_infinity"
    STREAM_SECRET_KEY: str = "ruzelo_audio_stream_authorization_ticket_secret_key"
    ALGORITHM: str = "HS256"
    
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24       # 24 Hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30              # 30 Days
    STREAM_TICKET_EXPIRE_MINUTES: int = 60           # 1 Hour stream authorization
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./ruzelo.db"
    
    # Redis / Cache
    REDIS_URL: str = "redis://localhost:6379/0"
    CACHE_TTL_SECONDS: int = 300
    
    # Audio Storage & Streaming Tiers
    MEDIA_DIR: str = "./media"
    AUDIO_DIR: str = "./media/audio"
    
    # Tier Bitrate Limits (kbps)
    TIER_FREE_MAX_BITRATE: int = 160
    TIER_INFINITE_MAX_BITRATE: int = 1411  # Lossless FLAC / 320kbps MP3
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "*"
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
