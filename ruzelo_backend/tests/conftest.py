import asyncio
import os
import sys
from typing import AsyncGenerator
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Ensure app package is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import Base, get_db
from app.models.atmosphere import Atmosphere
from app.models.track import Track
from app.models.user import User
from main import app

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(TEST_DATABASE_URL, future=True)
TestingSessionLocal = async_sessionmaker(
    test_engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
    class_=AsyncSession,
)


@pytest.fixture(scope="function", autouse=True)
async def setup_test_database():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed test track & atmosphere
    async with TestingSessionLocal() as session:
        sample_track = Track(
            id="track_test_1",
            title="Neon Odyssey Test",
            artist="Aether Wave",
            album="Cyber Horizon",
            duration_seconds=225,
            cover_art_url="https://example.com/cover.jpg",
            genre="Synthwave",
            bpm=128.0,
            energy=0.90,
            valence=0.75,
            danceability=0.82,
            acousticness=0.10,
            mood_tags="cyberpunk,neon,driving",
            format="flac",
            bitrate_kbps=1411,
        )
        sample_atmo = Atmosphere(
            id="cyber_aura",
            name="Cyber Aura",
            description="Electric violet and neon cyan glow",
            primary_color="#8B5CF6",
            secondary_color="#06B6D4",
            accent_color="#EC4899",
            shader_speed=1.2,
            noise_scale=1.1,
            audio_reactive_factor=1.3,
        )
        session.add(sample_track)
        session.add(sample_atmo)
        await session.commit()

    yield

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture
async def async_client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
