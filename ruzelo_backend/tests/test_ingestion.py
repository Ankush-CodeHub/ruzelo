import io
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_track_upload_and_dsp_ingestion(async_client: AsyncClient):
    """Tests master audio upload with automated DSP loudness, BPM, and ISRC extraction."""
    # Synthetic PCM WAV file payload
    wav_header = (
        b"RIFF\x24\x08\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00"
        b"\x10\xb1\x02\x00\x04\x00\x10\x00data\x00\x08\x00\x00"
    )
    # 2048 bytes of audio sine samples
    pcm_samples = b"\x00\x10\x00\x20" * 512
    mock_audio_file = wav_header + pcm_samples

    files = {"file": ("new_anthem.wav", mock_audio_file, "audio/wav")}
    data = {
        "title": "Raag Yaman Electro-Acoustic",
        "artist": "Arijit Singh",
        "album": "Saffron Horizon 2026",
        "genre": "Bollywood Romance",
        "mood_tags": "saffron,romantic,sitar",
    }

    response = await async_client.post("/api/v1/ingestion/upload", files=files, data=data)
    assert response.status_code == 201
    res_data = response.json()

    assert "track_id" in res_data
    assert res_data["title"] == "Raag Yaman Electro-Acoustic"
    assert res_data["artist"] == "Arijit Singh"
    assert "isrc" in res_data
    assert res_data["isrc"].startswith("IN-RZL-")
    assert "dsp_metrics" in res_data
    assert "lufs" in res_data["dsp_metrics"]
    assert "bpm" in res_data["dsp_metrics"]
    assert "energy" in res_data["dsp_metrics"]
    assert res_data["status"] == "ingested_and_live"


@pytest.mark.asyncio
async def test_ddex_batch_ingestion(async_client: AsyncClient):
    """Tests simulated enterprise DDEX ERN batch delivery from music distributors."""
    payload = {
        "distributor_name": "Universal Music India",
        "batch_reference": "DDEX-ERN-2026-0814",
        "tracks": [
            {
                "title": "Bhangra Ignite",
                "artist_name": "Diljit Dosanjh",
                "genre": "Punjabi Pop",
                "mood_tags": "bhangra,dhol,festival",
            },
            {
                "title": "Sufi Ecstasy",
                "artist_name": "A. R. Rahman",
                "genre": "Sufi Mystic",
                "mood_tags": "sufi,flute,peace",
            },
        ],
    }

    response = await async_client.post("/api/v1/ingestion/ddex-batch", json=payload)
    assert response.status_code == 201
    res_data = response.json()

    assert res_data["distributor"] == "Universal Music India"
    assert res_data["ingested_count"] == 2
    assert len(res_data["tracks"]) == 2
    assert res_data["tracks"][0]["title"] == "Bhangra Ignite"
    assert res_data["tracks"][1]["title"] == "Sufi Ecstasy"


@pytest.mark.asyncio
async def test_release_radar_endpoint(async_client: AsyncClient):
    """Tests personalized Release Radar discovery endpoint."""
    response = await async_client.get("/api/v1/tracks/release-radar?energy=0.85&limit=5")
    assert response.status_code == 200
    tracks = response.json()
    assert isinstance(tracks, list)
    assert len(tracks) >= 1
    assert "stream_url" in tracks[0]


@pytest.mark.asyncio
async def test_new_releases_endpoint(async_client: AsyncClient):
    """Tests global new releases feed endpoint."""
    response = await async_client.get("/api/v1/tracks/new-releases?limit=10")
    assert response.status_code == 200
    tracks = response.json()
    assert isinstance(tracks, list)
    assert len(tracks) >= 1
