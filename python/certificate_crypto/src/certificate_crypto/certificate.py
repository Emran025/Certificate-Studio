"""Certificate verification record canonicalization and signing."""
from typing import Any
from .hashing import hash_bytes
from .serialization import canonical_json, b64u_encode, b64u_decode
from .signing import sign, verify

RECORD_FORMAT = "certificate-verification-v1"
REQUIRED = ("institution_id", "project_id", "certificate_id")

def canonical_record(record: dict[str, Any]) -> bytes:
    return canonical_json(record)

def create_record(fields: dict[str, Any], document: bytes, private_key) -> dict[str, Any]:
    record = dict(fields)
    for name in REQUIRED:
        if not isinstance(record.get(name), str) or not record[name]:
            raise ValueError(f"{name} is required")
    record["format"] = RECORD_FORMAT
    record["document_hash"] = b64u_encode(hash_bytes(document))
    record["signature"] = b64u_encode(sign(canonical_record(record), private_key))
    return record

def verify_record(record: dict[str, Any], document: bytes, public_key) -> bool:
    try:
        if record.get("format") != RECORD_FORMAT or any(not record.get(x) for x in REQUIRED):
            return False
        signature = b64u_decode(record["signature"])
        unsigned = dict(record)
        del unsigned["signature"]
        return unsigned.get("document_hash") == b64u_encode(hash_bytes(document)) and verify(canonical_record(unsigned), signature, public_key)
    except (KeyError, TypeError, ValueError):
        return False
