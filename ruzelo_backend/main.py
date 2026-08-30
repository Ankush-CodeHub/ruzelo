import asyncio
import logging
import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from app.api.v1.artists import router as artists_router
from app.api.v1.atmosphere import router as atmosphere_router
from app.api.v1.auth import router as auth_router
from app.api.v1.ingestion import router as ingestion_router
from app.api.v1.playlists import router as playlists_router
from app.api.v1.streaming import router as streaming_router
from app.api.v1.tracks import router as tracks_router
from app.core.config import settings
from app.core.database import Base, async_session_factory, engine
from app.models.artist import Artist
from app.models.atmosphere import Atmosphere
from app.models.playlist import Playlist, playlist_tracks
from app.models.track import Track
from app.models.user import User
from app.services.live_music_gateway import LiveMusicGateway

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ruzelo_backend")


async def seed_initial_data():
    """Seeds the database and warms live music cache."""
    async with async_session_factory() as session:
        existing_artists = (await session.execute(select(Artist))).scalars().all()
        existing_artist_ids = {a.id for a in existing_artists}
        
        sample_artists = [
            Artist(
                id="artist_ar_rahman",
                name="A. R. Rahman",
                bio="Oscar and Grammy-winning pioneer of Indian cinematic soundscapes, Sufi mysticism, and symphonic fusion.",
                image_url="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800",
                banner_url="https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200",
                monthly_listeners=18500000,
                genre="Bollywood / Sufi",
            ),
            Artist(
                id="artist_arijit_singh",
                name="Arijit Singh",
                bio="The iconic voice of contemporary Indian romantic ballads, soulful acoustics, and raw emotive expression.",
                image_url="https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800",
                banner_url="https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=1200",
                monthly_listeners=34200000,
                genre="Bollywood Romance",
            ),
            Artist(
                id="artist_diljit_dosanjh",
                name="Diljit Dosanjh",
                bio="Global Punjabi powerhouse fusing high-energy Bhangra rhythms, modern Desi hip-hop, and infectious festival grooves.",
                image_url="https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=800",
                banner_url="https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=1200",
                monthly_listeners=19800000,
                genre="Punjabi Pop",
            ),
            Artist(
                id="artist_anirudh",
                name="Anirudh Ravichander",
                bio="South Indian rockstar composer electrifying world cinema with chart-topping electro-folk and orchestral power.",
                image_url="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800",
                banner_url="https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1200",
                monthly_listeners=21400000,
                genre="South Indian Cinema",
            ),
            Artist(
                id="artist_prateek_kuhad",
                name="Prateek Kuhad",
                bio="Globally celebrated Indian indie singer-songwriter delivering intimate acoustic folk, gentle fingerpicking, and poetic lyrics.",
                image_url="https://images.unsplash.com/photo-1465847899084-d164df4dedc6?q=80&w=800",
                banner_url="https://images.unsplash.com/photo-1465847899084-d164df4dedc6?q=80&w=1200",
                monthly_listeners=8400000,
                genre="Desi Indie / Lo-Fi",
            ),
        ]
        for a in sample_artists:
            if a.id not in existing_artist_ids:
                session.add(a)

        await session.commit()
        logger.info("Ruzelo database initialized.")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing database schemas...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await seed_initial_data()
    # Preload and warm up live music catalog in the background
    asyncio.create_task(LiveMusicGateway.get_latest_songs(25))
    asyncio.create_task(LiveMusicGateway.get_live_genre_playlists())
    yield
    await engine.dispose()
    logger.info("Database engine connections closed.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(tracks_router, prefix=settings.API_V1_STR)
app.include_router(artists_router, prefix=settings.API_V1_STR)
app.include_router(playlists_router, prefix=settings.API_V1_STR)
app.include_router(atmosphere_router, prefix=settings.API_V1_STR)
app.include_router(streaming_router, prefix=settings.API_V1_STR)
app.include_router(ingestion_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Health"])
async def root():
    return {
        "app": settings.PROJECT_NAME,
        "status": "online",
        "version": "1.0.0",
        "catalog": "Real Music Live Streaming Network",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"}
