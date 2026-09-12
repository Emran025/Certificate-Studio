import json
from typing import Any
from .serialization import b64u_decode, b64u_encode, canonical_json
from .certificate import verify_record
from .hashing import hash_bytes

QR_SCHEME = "cstudio://verify/v1/"

def encode_qr_payload(record: dict[str, Any]) -> str:
    return QR_SCHEME + b64u_encode(canonical_json(record))

def decode_qr_payload(payload: str) -> dict[str, Any]:
    if not payload.startswith(QR_SCHEME):
        raise ValueError("unsupported verification QR payload")
    value = json.loads(b64u_decode(payload[len(QR_SCHEME):]).decode("utf-8"))
    if not isinstance(value, dict):
        raise ValueError("verification QR payload must be an object")
    return value

def verify_qr_payload(payload: str, document: bytes, public_key) -> bool:
    record = decode_qr_payload(payload)
    return record.get("document_hash") == b64u_encode(hash_bytes(document)) and verify_record(record, document, public_key)
