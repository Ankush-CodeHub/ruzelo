from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.database import get_db
from app.core.middleware import AuthenticatedUser, get_current_user
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_stream_ticket,
    decode_refresh_token,
    get_password_hash,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import (
    RefreshTokenRequest,
    StreamTicketResponse,
    TierUpgradeRequest,
    TokenResponse,
    UserCreate,
    UserProfile,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse)
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)) -> Any:
    # Check if username or email exists
    existing = await db.execute(
        select(User).where((User.username == user_in.username) | (User.email == user_in.email))
    )
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered",
        )

    new_user = User(
        username=user_in.username,
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        tier="infinite",  # Default VIP for demo
        preferred_atmosphere=user_in.preferred_atmosphere or "cyber_aura",
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    access_token = create_access_token(subject=new_user.username, tier=new_user.tier)
    refresh_token = create_refresh_token(subject=new_user.username)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=new_user.id,
        tier=new_user.tier,
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(User).where(User.username == form_data.username)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        # Demo fallback: allow seamless login for testing
        access_token = create_access_token(subject=form_data.username, tier="infinite")
        refresh_token = create_refresh_token(subject=form_data.username)
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user_id="user_demo_1",
            tier="infinite",
        )

    access_token = create_access_token(subject=user.username, tier=user.tier)
    refresh_token = create_refresh_token(subject=user.username)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        tier=user.tier,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest, db: AsyncSession = Depends(get_db)) -> Any:
    payload = decode_refresh_token(request.refresh_token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    username = payload["sub"]
    access_token = create_access_token(subject=username, tier="infinite")
    new_refresh = create_refresh_token(subject=username)

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=username,
        tier="infinite",
    )


@router.post("/guest", response_model=TokenResponse)
async def guest_login() -> Any:
    access_token = create_access_token(subject="guest_listener", tier="infinite")
    refresh_token = create_refresh_token(subject="guest_listener")
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id="guest_listener",
        tier="infinite",
    )


@router.get("/me", response_model=UserProfile)
async def get_current_user_profile(
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(User).where(User.username == current_user.username)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        from datetime import datetime, timezone
        return UserProfile(
            id=current_user.user_id,
            username=current_user.username,
            email=f"{current_user.username}@ruzelo.audio",
            tier=current_user.tier,
            preferred_atmosphere="cyber_aura",
            created_at=datetime.now(timezone.utc),
        )

    return UserProfile(
        id=user.id,
        username=user.username,
        email=user.email,
        tier=user.tier,
        preferred_atmosphere=user.preferred_atmosphere,
        created_at=user.created_at,
    )


@router.post("/stream-ticket/{track_id}", response_model=StreamTicketResponse)
async def issue_stream_ticket(
    track_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> Any:
    """Issues a short-lived signed token for authorized audio playback."""
    ticket = create_stream_ticket(track_id=track_id, user_id=current_user.user_id, tier=current_user.tier)
    stream_url = f"{settings.API_V1_STR}/tracks/{track_id}/stream?ticket={ticket}"
    return StreamTicketResponse(
        ticket=ticket,
        stream_url=stream_url,
        expires_in=settings.STREAM_TICKET_EXPIRE_MINUTES * 60,
    )


@router.post("/upgrade-tier", response_model=UserProfile)
async def upgrade_user_tier(
    req: TierUpgradeRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Any:
    stmt = select(User).where(User.username == current_user.username)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    if user:
        user.tier = req.tier
        await db.commit()
        await db.refresh(user)
    return await get_current_user_profile(current_user=current_user, db=db)
