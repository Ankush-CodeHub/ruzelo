import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_live_search_real_songs_endpoint(async_client: AsyncClient):
    """Tests live search across real music catalog."""
    response = await async_client.get("/api/v1/tracks/live-search?q=Kesariya&limit=5")
    assert response.status_code == 200
    results = response.json()
    assert isinstance(results, list)
    assert len(results) >= 1
    first = results[0]
    assert "title" in first
    assert "artist" in first
    assert "stream_url" in first
    assert "cover_art_url" in first
    assert first["is_real_stream"] is True


@pytest.mark.asyncio
async def test_live_trending_songs_endpoint(async_client: AsyncClient):
    """Tests live trending real songs endpoint across categories."""
    response = await async_client.get("/api/v1/tracks/live-trending?category=punjabi&limit=5")
    assert response.status_code == 200
    results = response.json()
    assert isinstance(results, list)
    assert len(results) >= 1
    assert "title" in results[0]
    assert "stream_url" in results[0]
