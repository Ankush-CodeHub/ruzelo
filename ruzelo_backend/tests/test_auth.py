import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_user_registration_and_login_flow(async_client: AsyncClient):
    """Tests end-to-end user registration, access token generation, and login."""
    reg_payload = {
        "username": "neon_traveler",
        "email": "traveler@ruzelo.audio",
        "password": "SecureAtmospherePassword2026!",
        "preferred_atmosphere": "cyber_aura",
    }
    reg_response = await async_client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_response.status_code == 200
    token_data = reg_response.json()
    assert "access_token" in token_data
    assert "refresh_token" in token_data
    assert token_data["token_type"] == "bearer"

    # Login with credentials
    login_data = {
        "username": "neon_traveler",
        "password": "SecureAtmospherePassword2026!",
    }
    login_response = await async_client.post("/api/v1/auth/login", data=login_data)
    assert login_response.status_code == 200
    access_token = login_response.json()["access_token"]

    # Access protected /auth/me
    headers = {"Authorization": f"Bearer {access_token}"}
    me_response = await async_client.get("/api/v1/auth/me", headers=headers)
    assert me_response.status_code == 200
    user_profile = me_response.json()
    assert user_profile["username"] == "neon_traveler"
    assert user_profile["email"] == "traveler@ruzelo.audio"


@pytest.mark.asyncio
async def test_guest_login_and_token_refresh(async_client: AsyncClient):
    """Tests guest token generation and refresh token rotation."""
    guest_response = await async_client.post("/api/v1/auth/guest")
    assert guest_response.status_code == 200
    guest_data = guest_response.json()
    assert "access_token" in guest_data
    assert "refresh_token" in guest_data

    # Refresh token
    refresh_payload = {"refresh_token": guest_data["refresh_token"]}
    refresh_response = await async_client.post("/api/v1/auth/refresh", json=refresh_payload)
    assert refresh_response.status_code == 200
    new_token_data = refresh_response.json()
    assert "access_token" in new_token_data
    assert "refresh_token" in new_token_data
