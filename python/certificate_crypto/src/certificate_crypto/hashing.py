import hashlib
import hmac
from typing import Any
from .serialization import canonical_json, b64u_encode

HASH_ALGORITHM = "sha256"

def hash_bytes(data: bytes) -> bytes:
    return hashlib.sha256(data).digest()

def hash_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def hash_json(value: Any) -> bytes:
    return hash_bytes(canonical_json(value))

def hash_json_b64(value: Any) -> str:
    return b64u_encode(hash_json(value))

def verify_hash(data: bytes, expected: bytes | str) -> bool:
    actual = hash_bytes(data)
    wanted = bytes.fromhex(expected) if isinstance(expected, str) and len(expected) == 64 else expected
    return hmac.compare_digest(actual, wanted)
