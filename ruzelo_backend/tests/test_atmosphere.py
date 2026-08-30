import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_all_atmospheres(async_client: AsyncClient):
    """Tests listing all registered atmosphere presets."""
    response = await async_client.get("/api/v1/atmosphere")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["id"] == "cyber_aura"


@pytest.mark.asyncio
async def test_get_atmosphere_shader_uniforms(async_client: AsyncClient):
    """Tests uniform generation for Flutter FragmentProgram binding."""
    response = await async_client.get("/api/v1/atmosphere/cyber_aura/uniforms")
    assert response.status_code == 200
    data = response.json()
    assert "color_a_rgb" in data
    assert "color_b_rgb" in data
    assert len(data["color_a_rgb"]) == 3
    assert all(0.0 <= c <= 1.0 for c in data["color_a_rgb"])


@pytest.mark.asyncio
async def test_atmosphere_recommendations_with_energy_and_time_of_day(async_client: AsyncClient):
    """Tests dynamic track sequence curation based on user energy slider and time-of-day context."""
    payload = {
        "energy_level": 0.85,
        "time_of_day": "Midnight Groove",
        "atmosphere_tag": "Cyber Aura",
        "limit": 5,
    }
    response = await async_client.post("/api/v1/atmosphere/recommendations", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "curated_tracks" in data
    assert "atmosphere" in data
    assert data["energy_level"] == 0.85
    assert data["time_of_day"] == "Midnight Groove"
