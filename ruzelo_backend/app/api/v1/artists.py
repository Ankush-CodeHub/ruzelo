from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.artist import Artist
from app.models.track import Track
from app.schemas.artist import ArtistCreate, ArtistDetail, ArtistRead
from app.schemas.track import TrackRead

router = APIRouter(prefix="/artists", tags=["Artists"])


@router.get("", response_model=List[ArtistRead])
async def list_artists(
    genre: str = Query(None),
    limit: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(Artist)
    if genre:
        stmt = stmt.where(Artist.genre.ilike(f"%{genre}%"))
    stmt = stmt.limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{artist_id}", response_model=ArtistDetail)
async def get_artist_detail(artist_id: str, db: AsyncSession = Depends(get_db)) -> Any:
    stmt = select(Artist).where(Artist.id == artist_id)
    result = await db.execute(stmt)
    artist = result.scalar_one_or_none()

    if not artist:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Artist with ID '{artist_id}' not found",
        )

    # Fetch top tracks by artist name or ID
    tracks_stmt = (
        select(Track)
        .where((Track.artist_id == artist_id) | (Track.artist.ilike(artist.name)))
        .order_by(Track.play_count.desc())
        .limit(10)
    )
    tracks_result = await db.execute(tracks_stmt)
    tracks = tracks_result.scalars().all()

    track_reads = [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in tracks
    ]

    return ArtistDetail(
        id=artist.id,
        name=artist.name,
        bio=artist.bio,
        image_url=artist.image_url,
        banner_url=artist.banner_url,
        monthly_listeners=artist.monthly_listeners,
        genre=artist.genre,
        created_at=artist.created_at,
        updated_at=artist.updated_at,
        top_tracks=track_reads,
    )


@router.post("", response_model=ArtistRead, status_code=status.HTTP_201_CREATED)
async def create_artist(artist_in: ArtistCreate, db: AsyncSession = Depends(get_db)) -> Any:
    artist = Artist(**artist_in.model_dump())
    db.add(artist)
    await db.commit()
    await db.refresh(artist)
    return artist
