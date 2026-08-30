from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.middleware import AuthenticatedUser, get_current_user
from app.models.favorite import Favorite
from app.models.track import Track
from app.schemas.track import TrackCreate, TrackListResponse, TrackRead, TrackUpdate
from app.services.real_music_service import RealMusicService
from app.services.recommendation_engine import RecommendationEngine

router = APIRouter(prefix="/tracks", tags=["Tracks & Real Live Music"])


@router.get("", response_model=TrackListResponse)
async def get_tracks(
    genre: Optional[str] = Query(None, description="Filter by genre"),
    mood: Optional[str] = Query(None, description="Filter by mood tag"),
    q: Optional[str] = Query(None, description="Search query"),
    min_energy: Optional[float] = Query(None, ge=0.0, le=1.0),
    max_energy: Optional[float] = Query(None, ge=0.0, le=1.0),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(Track)

    if genre:
        stmt = stmt.where(Track.genre.ilike(f"%{genre}%"))
    if mood:
        stmt = stmt.where(Track.mood_tags.ilike(f"%{mood}%"))
    if min_energy is not None:
        stmt = stmt.where(Track.energy >= min_energy)
    if max_energy is not None:
        stmt = stmt.where(Track.energy <= max_energy)
    if q:
        search_pattern = f"%{q}%"
        stmt = stmt.where(
            or_(
                Track.title.ilike(search_pattern),
                Track.artist.ilike(search_pattern),
                Track.album.ilike(search_pattern),
                Track.genre.ilike(search_pattern),
            )
        )

    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    tracks = result.scalars().all()

    track_reads = [
        TrackRead.model_validate(track).model_copy(
            update={"stream_url": f"/api/v1/tracks/{track.id}/stream"}
        )
        for track in tracks
    ]

    return TrackListResponse(
        items=track_reads,
        total=len(track_reads),
        page=page,
        page_size=page_size,
    )


@router.get("/live-search")
async def live_search_real_songs(
    q: str = Query(..., min_length=1, description="Song title, artist, or album query"),
    limit: int = Query(20, ge=1, le=50),
    country: str = Query("IN", description="Country storefront code"),
) -> List[Dict[str, Any]]:
    """Live search across millions of real songs. Returns official artist metadata, 600x600 artwork, and direct stream URLs."""
    return await RealMusicService.search_real_songs(query=q, limit=limit, country=country)


@router.get("/live-trending")
async def get_live_trending_songs(
    category: str = Query("bollywood", description="Category: bollywood, punjabi, sufi, south, lofi, global"),
    limit: int = Query(15, ge=1, le=30),
) -> List[Dict[str, Any]]:
    """Retrieves current live trending chart tracks with real streaming audio."""
    return await RealMusicService.get_trending_real_songs(category=category, limit=limit)


@router.get("/live-latest")
async def get_live_latest_songs(
    limit: int = Query(25, ge=1, le=50),
) -> List[Dict[str, Any]]:
    """Dynamically pulls latest real music releases from live catalog without any hardcoded defaults."""
    from app.services.live_music_gateway import LiveMusicGateway
    return await LiveMusicGateway.get_latest_songs(limit=limit)


@router.get("/live-playlists")
@router.get("/live-mood-playlists")
async def get_live_genre_playlists() -> List[Dict[str, Any]]:
    """Dynamically pulls diverse Genre and Curated Playlists with real songs pre-populated from live catalog."""
    from app.services.live_music_gateway import LiveMusicGateway
    return await LiveMusicGateway.get_live_genre_playlists()


@router.post("/last-played")
async def save_last_played_track(track_data: Dict[str, Any]) -> Dict[str, Any]:
    """Persists the user's last played track so it is automatically restored on app reload."""
    from app.services.cache_service import cache_service
    await cache_service.set("ruzelo:user:last_played_track", track_data, ttl_seconds=86400 * 30)
    return {"status": "saved", "track": track_data}


@router.get("/last-played")
async def get_last_played_track() -> Optional[Dict[str, Any]]:
    """Retrieves the last played track on startup."""
    from app.services.cache_service import cache_service
    return await cache_service.get("ruzelo:user:last_played_track")


@router.get("/resolve-full")
async def resolve_full_song(
    title: str = Query(..., description="Song title"),
    artist: str = Query(..., description="Artist name"),
    fallback_url: Optional[str] = Query(None, description="Optional fallback stream URL"),
) -> Dict[str, Any]:
    """Resolves and streams 100% FULL-LENGTH songs (full 3-6 minutes)."""
    from app.services.full_song_service import FullSongResolverService
    return await FullSongResolverService.resolve_full_song_stream(
        title=title,
        artist=artist,
        fallback_url=fallback_url,
    )


@router.get("/release-radar", response_model=List[TrackRead])
async def get_release_radar(
    energy: Optional[float] = Query(None, ge=0.0, le=1.0, description="Preferred listening energy level"),
    limit: int = Query(10, ge=1, le=30),
    db: AsyncSession = Depends(get_db),
) -> Any:
    """Personalized Release Radar: Discovers newly ingested music and orders by recency and energy match."""
    stmt = select(Track).order_by(desc(Track.created_at)).limit(50)
    result = await db.execute(stmt)
    all_recent = result.scalars().all()

    if energy is not None:
        sorted_tracks = sorted(all_recent, key=lambda t: abs((t.energy or 0.5) - energy))
    else:
        sorted_tracks = all_recent

    selected = sorted_tracks[:limit]
    return [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in selected
    ]


@router.get("/new-releases", response_model=List[TrackRead])
async def get_new_releases(
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
) -> Any:
    """Returns the latest music ingested across the platform."""
    stmt = select(Track).order_by(desc(Track.created_at)).limit(limit)
    result = await db.execute(stmt)
    tracks = result.scalars().all()

    return [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in tracks
    ]


@router.get("/{track_id}", response_model=TrackRead)
async def get_track_by_id(track_id: str, db: AsyncSession = Depends(get_db)) -> Any:
    stmt = select(Track).where(Track.id == track_id)
    result = await db.execute(stmt)
    track = result.scalar_one_or_none()

    if not track:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Track with ID '{track_id}' not found",
        )

    return TrackRead.model_validate(track).model_copy(
        update={"stream_url": f"/api/v1/tracks/{track.id}/stream"}
    )


@router.get("/{track_id}/recommendations", response_model=List[TrackRead])
async def get_track_recommendations(
    track_id: str,
    limit: int = Query(5, ge=1, le=20),
    db: AsyncSession = Depends(get_db),
) -> Any:
    target_track = (await db.execute(select(Track).where(Track.id == track_id))).scalar_one_or_none()
    if not target_track:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Target track with ID '{track_id}' not found",
        )

    all_tracks = (await db.execute(select(Track))).scalars().all()
    recommendations = RecommendationEngine.get_top_recommendations(
        target_track=target_track, candidate_tracks=all_tracks, limit=limit
    )

    return [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in recommendations
    ]


@router.post("/{track_id}/favorite")
async def toggle_favorite(
    track_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(Favorite).where(
        (Favorite.user_id == current_user.user_id) & (Favorite.track_id == track_id)
    )
    fav = (await db.execute(stmt)).scalar_one_or_none()
    if fav:
        await db.delete(fav)
        await db.commit()
        return {"favorited": False, "track_id": track_id}
    else:
        new_fav = Favorite(user_id=current_user.user_id, track_id=track_id)
        db.add(new_fav)
        await db.commit()
        return {"favorited": True, "track_id": track_id}
