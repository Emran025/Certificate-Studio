"""Deterministic wire serialization used by Dart interoperability."""
import base64
import json
from typing import Any


def canonical_json(value: Any) -> bytes:
    """Encode JSON as UTF-8, sorted, compact, and without ASCII escaping."""
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")


def b64u_encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def b64u_decode(value: str) -> bytes:
    if not isinstance(value, str):
        raise ValueError("expected base64url string")
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))
