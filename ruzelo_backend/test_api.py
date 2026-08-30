import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pytest
from fastapi.testclient import TestClient
from main import app

def test_full_pipeline():
    with TestClient(app) as client:
        # 1. Health check
        res = client.get("/health")
        assert res.status_code == 200
        assert res.json() == {"status": "healthy"}
        print("✓ Health check passed")

        # 2. Guest login & auth token
        res = client.post("/api/v1/auth/guest")
        assert res.status_code == 200
        token_data = res.json()
        assert "access_token" in token_data
        token = token_data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("✓ Auth token passed")

        # 3. Track listing & filtering
        res = client.get("/api/v1/tracks", headers=headers)
        assert res.status_code == 200
        tracks_data = res.json()
        assert len(tracks_data["items"]) >= 3
        print(f"✓ Track listing passed ({len(tracks_data['items'])} tracks found)")

        # 4. Atmosphere Presets & Recommendations
        res = client.get("/api/v1/atmosphere", headers=headers)
        assert res.status_code == 200
        atmospheres = res.json()
        assert len(atmospheres) >= 4
        print(f"✓ Atmospheres passed ({len(atmospheres)} presets found)")

        rec_payload = {
            "energy_level": 0.85,
            "time_of_day": "Midnight Groove",
            "atmosphere_tag": "Cyber Aura",
            "limit": 5,
        }
        res = client.post("/api/v1/atmosphere/recommendations", json=rec_payload, headers=headers)
        assert res.status_code == 200
        rec_data = res.json()
        assert "curated_tracks" in rec_data
        assert len(rec_data["curated_tracks"]) > 0
        print("✓ Atmosphere recommendations with dynamic energy weighting passed")

        # 5. Artists endpoint
        res = client.get("/api/v1/artists", headers=headers)
        assert res.status_code == 200
        artists = res.json()
        assert len(artists) >= 3
        print(f"✓ Artist catalog passed ({len(artists)} artists found)")

        # 6. Stream ticket & Byte-range audio streaming
        track_id = "track_1"
        res = client.post(f"/api/v1/auth/stream-ticket/{track_id}", headers=headers)
        assert res.status_code == 200
        ticket_data = res.json()
        assert "ticket" in ticket_data
        ticket = ticket_data["ticket"]
        print("✓ Stream ticket issuance passed")

        stream_headers = {"Range": "bytes=0-2048"}
        res = client.get(f"/api/v1/tracks/{track_id}/stream?ticket={ticket}", headers=stream_headers)
        assert res.status_code == 206
        assert "Content-Range" in res.headers
        assert "audio/" in res.headers.get("Content-Type", "")
        assert len(res.content) == 2049
        print(f"✓ Byte-Range Audio Streaming passed (Received {len(res.content)} bytes with HTTP 206)")

if __name__ == "__main__":
    test_full_pipeline()
    print("\nALL VERIFICATION TESTS COMPLETED SUCCESSFULLY!")
