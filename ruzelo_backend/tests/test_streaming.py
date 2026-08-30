import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_full_audio_stream(async_client: AsyncClient):
    """Tests streaming full track audio without Range header."""
    response = await async_client.get("/api/v1/tracks/track_test_1/stream")
    assert response.status_code == 200
    assert "audio/" in response.headers.get("Content-Type", "")
    assert "Accept-Ranges" in response.headers
    assert response.headers["Accept-Ranges"] == "bytes"
    assert len(response.content) > 0


@pytest.mark.asyncio
async def test_single_byte_range_request(async_client: AsyncClient):
    """Tests byte-range streaming with Range: bytes=0-1023."""
    headers = {"Range": "bytes=0-1023"}
    response = await async_client.get("/api/v1/tracks/track_test_1/stream", headers=headers)
    assert response.status_code == 206
    assert response.headers.get("Content-Range", "").startswith("bytes 0-1023/")
    assert response.headers.get("Content-Length") == "1024"
    assert len(response.content) == 1024


@pytest.mark.asyncio
async def test_open_ended_byte_range_request(async_client: AsyncClient):
    """Tests open-ended byte-range streaming with Range: bytes=1024-."""
    headers = {"Range": "bytes=1024-"}
    response = await async_client.get("/api/v1/tracks/track_test_1/stream", headers=headers)
    assert response.status_code == 206
    assert "Content-Range" in response.headers
    assert response.headers.get("Content-Range", "").startswith("bytes 1024-")
    assert len(response.content) > 0


@pytest.mark.asyncio
async def test_invalid_out_of_bounds_byte_range(async_client: AsyncClient):
    """Tests HTTP 416 response on out-of-bounds byte range."""
    headers = {"Range": "bytes=99999999-999999999"}
    response = await async_client.get("/api/v1/tracks/track_test_1/stream", headers=headers)
    assert response.status_code == 416


@pytest.mark.asyncio
async def test_stream_nonexistent_track_returns_404(async_client: AsyncClient):
    """Tests 404 response for non-existent track ID."""
    response = await async_client.get("/api/v1/tracks/non_existent_track_id/stream")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_stream_ticket_issuance_and_verification(async_client: AsyncClient):
    """Tests issuing a stream authorization ticket and accessing stream with the ticket query parameter."""
    auth_resp = await async_client.post("/api/v1/auth/guest")
    assert auth_resp.status_code == 200
    token = auth_resp.json()["access_token"]

    ticket_resp = await async_client.post(
        "/api/v1/auth/stream-ticket/track_test_1",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert ticket_resp.status_code == 200
    ticket = ticket_resp.json()["ticket"]
    assert len(ticket) > 20

    stream_resp = await async_client.get(f"/api/v1/tracks/track_test_1/stream?ticket={ticket}")
    assert stream_resp.status_code == 200
