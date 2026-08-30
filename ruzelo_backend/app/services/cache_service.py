import time
from typing import Any, Dict, Optional
import json


class InMemoryCacheService:
    """High-performance async in-memory cache with TTL support (Redis fallback/ready)."""

    def __init__(self):
        self._store: Dict[str, Dict[str, Any]] = {}

    async def get(self, key: str) -> Optional[Any]:
        if key in self._store:
            entry = self._store[key]
            if entry["expires_at"] > time.time():
                return entry["value"]
            else:
                del self._store[key]
        return None

    async def set(self, key: str, value: Any, ttl_seconds: int = 300) -> None:
        self._store[key] = {
            "value": value,
            "expires_at": time.time() + ttl_seconds,
        }

    async def delete(self, key: str) -> None:
        self._store.pop(key, None)

    async def clear(self) -> None:
        self._store.clear()


cache_service = InMemoryCacheService()
