from typing import Any, List, Tuple
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.atmosphere import Atmosphere
from app.models.track import Track
from app.schemas.atmosphere import (
    AtmosphereCreate,
    AtmosphereRead,
    AtmosphereRecommendationRequest,
    AtmosphereRecommendationResponse,
    AtmosphereUpdate,
    ShaderUniformsResponse,
)
from app.schemas.track import TrackRead
from app.services.recommendation_engine import RecommendationEngine

router = APIRouter(prefix="/atmosphere", tags=["Atmosphere"])


def hex_to_rgb_tuple(hex_str: str) -> Tuple[float, float, float]:
    hex_clean = hex_str.lstrip("#")
    if len(hex_clean) == 6:
        r = int(hex_clean[0:2], 16) / 255.0
        g = int(hex_clean[2:4], 16) / 255.0
        b = int(hex_clean[4:6], 16) / 255.0
        return (r, g, b)
    return (0.5, 0.5, 0.5)


@router.get("", response_model=List[AtmosphereRead])
async def get_all_atmospheres(db: AsyncSession = Depends(get_db)) -> Any:
    stmt = select(Atmosphere)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{atmosphere_id}", response_model=AtmosphereRead)
async def get_atmosphere_by_id(atmosphere_id: str, db: AsyncSession = Depends(get_db)) -> Any:
    stmt = select(Atmosphere).where(Atmosphere.id == atmosphere_id)
    result = await db.execute(stmt)
    atmosphere = result.scalar_one_or_none()

    if not atmosphere:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Atmosphere with ID '{atmosphere_id}' not found",
        )
    return atmosphere


@router.get("/{atmosphere_id}/uniforms", response_model=ShaderUniformsResponse)
async def get_atmosphere_shader_uniforms(
    atmosphere_id: str, db: AsyncSession = Depends(get_db)
) -> Any:
    stmt = select(Atmosphere).where(Atmosphere.id == atmosphere_id)
    result = await db.execute(stmt)
    atmosphere = result.scalar_one_or_none()

    if not atmosphere:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Atmosphere with ID '{atmosphere_id}' not found",
        )

    return ShaderUniformsResponse(
        atmosphere_id=atmosphere.id,
        name=atmosphere.name,
        color_a_rgb=hex_to_rgb_tuple(atmosphere.primary_color),
        color_b_rgb=hex_to_rgb_tuple(atmosphere.secondary_color),
        color_c_rgb=hex_to_rgb_tuple(atmosphere.accent_color),
        speed=atmosphere.shader_speed,
        noise_scale=atmosphere.noise_scale,
        reactive_factor=atmosphere.audio_reactive_factor,
    )


@router.post("/recommendations", response_model=AtmosphereRecommendationResponse)
async def get_atmosphere_recommendations(
    req: AtmosphereRecommendationRequest,
    db: AsyncSession = Depends(get_db),
) -> Any:
    """Dynamically curates tracks based on target energy (0.0 to 1.0), time of day, and mood tag."""
    # Find matching atmosphere
    stmt = select(Atmosphere)
    if req.atmosphere_tag:
        stmt = stmt.where(Atmosphere.name.ilike(f"%{req.atmosphere_tag}%"))
    atmosphere = (await db.execute(stmt)).scalars().first()

    if not atmosphere:
        atmosphere = (await db.execute(select(Atmosphere))).scalars().first()
        if not atmosphere:
            # Fallback inline
            from datetime import datetime, timezone
            atmosphere = Atmosphere(
                id="cyber_aura",
                name="Cyber Aura",
                description="Electric space glow",
                primary_color="#8B5CF6",
                secondary_color="#06B6D4",
                accent_color="#EC4899",
            )

    all_tracks = (await db.execute(select(Track))).scalars().all()
    curated = RecommendationEngine.curate_by_atmosphere_and_energy(
        all_tracks=all_tracks,
        energy_level=req.energy_level,
        time_of_day=req.time_of_day or "Midnight Groove",
        atmosphere_tag=req.atmosphere_tag or atmosphere.name,
        limit=req.limit,
    )

    track_reads = [
        TrackRead.model_validate(t).model_copy(
            update={"stream_url": f"/api/v1/tracks/{t.id}/stream"}
        )
        for t in curated
    ]

    return AtmosphereRecommendationResponse(
        atmosphere=AtmosphereRead.model_validate(atmosphere),
        energy_level=req.energy_level,
        time_of_day=req.time_of_day or "Midnight Groove",
        curated_tracks=track_reads,
    )
