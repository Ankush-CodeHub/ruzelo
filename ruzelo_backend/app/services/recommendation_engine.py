import math
from typing import List, Optional, Tuple
from app.models.track import Track


class RecommendationEngine:
    """Acoustic feature vector distance matching engine for personalized track recommendations."""

    @staticmethod
    def extract_feature_vector(track: Track) -> List[float]:
        # 5-Dimensional acoustic vector: [BPM Normalized, Energy, Valence, Danceability, Acousticness]
        normalized_bpm = (track.bpm - 60.0) / 120.0
        return [
            normalized_bpm,
            track.energy,
            track.valence,
            track.danceability,
            track.acousticness,
        ]

    @classmethod
    def compute_similarity(cls, vec_a: List[float], vec_b: List[float]) -> float:
        """Computes cosine similarity between two multi-dimensional acoustic vectors."""
        dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
        norm_a = math.sqrt(sum(a * a for a in vec_a))
        norm_b = math.sqrt(sum(b * b for b in vec_b))

        if norm_a == 0.0 or norm_b == 0.0:
            return 0.0
        return dot_product / (norm_a * norm_b)

    @classmethod
    def get_top_recommendations(
        cls, target_track: Track, candidate_tracks: List[Track], limit: int = 5
    ) -> List[Track]:
        target_vec = cls.extract_feature_vector(target_track)
        scored: List[Tuple[float, Track]] = []

        for candidate in candidate_tracks:
            if candidate.id == target_track.id:
                continue
            cand_vec = cls.extract_feature_vector(candidate)
            similarity = cls.compute_similarity(target_vec, cand_vec)
            
            # Bonus for matching genre or mood tags
            if candidate.genre.lower() == target_track.genre.lower():
                similarity += 0.15

            scored.append((similarity, candidate))

        scored.sort(key=lambda x: x[0], reverse=True)
        return [item[1] for item in scored[:limit]]

    @classmethod
    def curate_by_atmosphere_and_energy(
        cls,
        all_tracks: List[Track],
        energy_level: float,
        time_of_day: Optional[str] = None,
        atmosphere_tag: Optional[str] = None,
        limit: int = 10,
    ) -> List[Track]:
        """Dynamically scores and filters tracks according to target energy, time-of-day acoustic profiles, and mood tags."""
        scored: List[Tuple[float, Track]] = []

        for track in all_tracks:
            # 1. Energy Delta Score (Closer energy = higher score)
            energy_diff = abs(track.energy - energy_level)
            energy_score = 1.0 - energy_diff

            # 2. Time-of-day acoustic weight
            tod_bonus = 0.0
            if time_of_day:
                tod_lower = time_of_day.lower()
                if "morning" in tod_lower and (track.acousticness > 0.3 or track.valence > 0.6):
                    tod_bonus = 0.2
                elif "midnight" in tod_lower and (track.energy > 0.6 or "night" in track.mood_tags or "deep" in track.mood_tags):
                    tod_bonus = 0.25
                elif "golden" in tod_lower and (track.valence > 0.5 or "sunset" in track.mood_tags):
                    tod_bonus = 0.2

            # 3. Atmosphere Tag Match
            tag_bonus = 0.0
            if atmosphere_tag:
                atmo_lower = atmosphere_tag.lower()
                if atmo_lower in track.mood_tags.lower() or atmo_lower in track.genre.lower():
                    tag_bonus = 0.35

            total_score = (energy_score * 0.5) + tod_bonus + tag_bonus + (track.danceability * 0.15)
            scored.append((total_score, track))

        scored.sort(key=lambda x: x[0], reverse=True)
        return [item[1] for item in scored[:limit]]
