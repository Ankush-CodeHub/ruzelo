from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.config import settings
from app.core.security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login",
    auto_error=False,
)


class AuthenticatedUser:
    def __init__(self, user_id: str, username: str, tier: str = "free"):
        self.user_id = user_id
        self.username = username
        self.tier = tier

    @property
    def is_infinite(self) -> bool:
        return self.tier.lower() == "infinite"


async def get_current_user_optional(
    token: Optional[str] = Depends(oauth2_scheme),
) -> Optional[AuthenticatedUser]:
    if not token:
        return None
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        return None
    return AuthenticatedUser(
        user_id=payload.get("user_id", payload["sub"]),
        username=payload["sub"],
        tier=payload.get("tier", "infinite"),
    )


async def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
) -> AuthenticatedUser:
    if not token:
        # Default guest user if no token provided in demo mode
        return AuthenticatedUser(user_id="guest_1", username="guest_listener", tier="infinite")
    
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return AuthenticatedUser(
        user_id=payload.get("user_id", payload["sub"]),
        username=payload["sub"],
        tier=payload.get("tier", "free"),
    )


def require_tier(minimum_tier: str = "infinite"):
    async def tier_checker(user: AuthenticatedUser = Depends(get_current_user)) -> AuthenticatedUser:
        if minimum_tier == "infinite" and not user.is_infinite:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Ruzelo Infinite subscription required for high-fidelity lossless FLAC streaming",
            )
        return user
    return tier_checker
