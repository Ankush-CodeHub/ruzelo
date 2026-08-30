import random
from locust import HttpUser, between, task


class RuzeloStreamingUser(HttpUser):
    wait_time = between(0.1, 0.5)
    token = None
    track_ids = ["track_1", "track_2", "track_3", "track_4"]

    def on_start(self):
        """Authenticates a guest user and retrieves access token."""
        response = self.client.post("/api/v1/auth/guest")
        if response.status_code == 200:
            self.token = response.json().get("access_token")

    @task(5)
    def stream_audio_initial_chunk(self):
        """Simulates initial audio buffering (first 128KB chunk)."""
        track_id = random.choice(self.track_ids)
        headers = {
            "Range": "bytes=0-131071",
            "Authorization": f"Bearer {self.token}" if self.token else "",
        }
        self.client.get(
            f"/api/v1/tracks/{track_id}/stream",
            headers=headers,
            name="/api/v1/tracks/[id]/stream (Initial 128KB Chunk)",
        )

    @task(3)
    def stream_audio_subsequent_chunk(self):
        """Simulates continuous audio scrubbing / streaming (e.g. 512KB-640KB)."""
        track_id = random.choice(self.track_ids)
        start_byte = random.randint(1, 10) * 131072
        end_byte = start_byte + 131071
        headers = {
            "Range": f"bytes={start_byte}-{end_byte}",
            "Authorization": f"Bearer {self.token}" if self.token else "",
        }
        self.client.get(
            f"/api/v1/tracks/{track_id}/stream",
            headers=headers,
            name="/api/v1/tracks/[id]/stream (Subsequent 128KB Chunk)",
        )

    @task(2)
    def fetch_atmosphere_recommendations(self):
        """Simulates dynamic energy slider adjustments while listening."""
        headers = {
            "Authorization": f"Bearer {self.token}" if self.token else "",
            "Content-Type": "application/json",
        }
        payload = {
            "energy_level": random.uniform(0.1, 0.95),
            "time_of_day": "Midnight Groove",
            "atmosphere_tag": "Cyber Aura",
            "limit": 5,
        }
        self.client.post(
            "/api/v1/atmosphere/recommendations",
            json=payload,
            headers=headers,
            name="/api/v1/atmosphere/recommendations",
        )

    @task(1)
    def browse_catalog(self):
        """Simulates browsing trending tracks and artist details."""
        self.client.get("/api/v1/tracks", name="/api/v1/tracks")
        self.client.get("/api/v1/atmosphere", name="/api/v1/atmosphere")
