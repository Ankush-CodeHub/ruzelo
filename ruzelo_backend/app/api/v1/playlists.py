from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, insert, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.middleware import AuthenticatedUser, get_current_user
from app.models.playlist import Playlist, playlist_tracks
from app.models.track import Track
from app.schemas.playlist import (
    PlaylistAddTrack,
    PlaylistCreate,
    PlaylistRead,
    PlaylistUpdate,
)
from app.schemas.track import TrackRead

router = APIRouter(prefix="/playlists", tags=["Playlists"])


@router.get("", response_model=List[PlaylistRead])
async def list_playlists(
    user_only: bool = False,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(Playlist)
    if user_only:
        stmt = stmt.where(Playlist.user_id == current_user.user_id)
    else:
        stmt = stmt.where((Playlist.is_public == True) | (Playlist.user_id == current_user.user_id))

    result = await db.execute(stmt)
    playlists = result.scalars().all()
    
    out: List[PlaylistRead] = []
    for pl in playlists:
        # Fetch associated tracks
        t_stmt = (
            select(Track)
            .join(playlist_tracks, Track.id == playlist_tracks.c.track_id)
            .where(playlist_tracks.c.playlist_id == pl.id)
            .order_by(playlist_tracks.c.position)
        )
        tracks = (await db.execute(t_stmt)).scalars().all()
        track_reads = [
            TrackRead.model_validate(t).model_copy(
                update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
            )
            for t in tracks
        ]
        out.append(
            PlaylistRead(
                id=pl.id,
                title=pl.title,
                description=pl.description,
                cover_image_url=pl.cover_image_url,
                atmosphere_tag=pl.atmosphere_tag,
                user_id=pl.user_id,
                is_public=pl.is_public,
                tracks=track_reads,
                track_count=len(track_reads),
                created_at=pl.created_at,
                updated_at=pl.updated_at,
            )
        )
    return out


@router.get("/{playlist_id}", response_model=PlaylistRead)
async def get_playlist_by_id(playlist_id: str, db: AsyncSession = Depends(get_db)) -> Any:
    stmt = select(Playlist).where(Playlist.id == playlist_id)
    result = await db.execute(stmt)
    pl = result.scalar_one_or_none()

    if not pl:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Playlist with ID '{playlist_id}' not found",
        )

    t_stmt = (
        select(Track)
        .join(playlist_tracks, Track.id == playlist_tracks.c.track_id)
        .where(playlist_tracks.c.playlist_id == pl.id)
        .order_by(playlist_tracks.c.position)
    )
    tracks = (await db.execute(t_stmt)).scalars().all()
    track_reads = [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in tracks
    ]

    return PlaylistRead(
        id=pl.id,
        title=pl.title,
        description=pl.description,
        cover_image_url=pl.cover_image_url,
        atmosphere_tag=pl.atmosphere_tag,
        user_id=pl.user_id,
        is_public=pl.is_public,
        tracks=track_reads,
        track_count=len(track_reads),
        created_at=pl.created_at,
        updated_at=pl.updated_at,
    )


@router.post("", response_model=PlaylistRead, status_code=status.HTTP_201_CREATED)
async def create_playlist(
    playlist_in: PlaylistCreate,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    pl = Playlist(
        title=playlist_in.title,
        description=playlist_in.description,
        cover_image_url=playlist_in.cover_image_url,
        atmosphere_tag=playlist_in.atmosphere_tag,
        user_id=current_user.user_id,
        is_public=playlist_in.is_public,
    )
    db.add(pl)
    await db.commit()
    await db.refresh(pl)

    if playlist_in.track_ids:
        for idx, track_id in enumerate(playlist_in.track_ids):
            await db.execute(
                insert(playlist_tracks).values(
                    playlist_id=pl.id,
                    track_id=track_id,
                    position=idx,
                )
            )
        await db.commit()

    return await get_playlist_by_id(pl.id, db)


@router.post("/{playlist_id}/tracks", response_model=PlaylistRead)
async def add_track_to_playlist(
    playlist_id: str,
    body: PlaylistAddTrack,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    # Check playlist exists
    pl = (await db.execute(select(Playlist).where(Playlist.id == playlist_id))).scalar_one_or_none()
    if not pl:
        raise HTTPException(status_code=404, detail="Playlist not found")

    await db.execute(
        insert(playlist_tracks).values(
            playlist_id=playlist_id,
            track_id=body.track_id,
            position=999,
        )
    )
    await db.commit()
    return await get_playlist_by_id(playlist_id, db)
