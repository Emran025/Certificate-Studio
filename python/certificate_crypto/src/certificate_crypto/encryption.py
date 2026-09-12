"""AES-256-GCM authenticated encryption with versioned JSON envelopes."""
import os
from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt
from .exceptions import AuthenticationError, InvalidEnvelopeError
from .serialization import b64u_encode, b64u_decode, canonical_json

ENVELOPE_FORMAT = "certificate-crypto-envelope-v1"

def _key(secret: bytes, salt: bytes) -> bytes:
    if len(secret) == 32:
        return secret
    return Scrypt(salt=salt, length=32, n=2**15, r=8, p=1).derive(secret)

def encrypt(plaintext: bytes, key: bytes, aad: bytes = b"") -> dict[str, str]:
    salt = os.urandom(16) if len(key) != 32 else b""
    nonce = os.urandom(12)
    ciphertext = AESGCM(_key(key, salt)).encrypt(nonce, plaintext, aad)
    return {"format": ENVELOPE_FORMAT, "algorithm": "AES-256-GCM", "kdf": "scrypt" if salt else "raw", "salt": b64u_encode(salt), "nonce": b64u_encode(nonce), "ciphertext": b64u_encode(ciphertext), "aad": b64u_encode(aad)}

def decrypt(envelope: dict[str, str], key: bytes, aad: bytes = b"") -> bytes:
    try:
        if envelope.get("format") != ENVELOPE_FORMAT or envelope.get("algorithm") != "AES-256-GCM":
            raise InvalidEnvelopeError("unsupported encryption envelope")
        encoded_aad = b64u_decode(envelope.get("aad", ""))
        if encoded_aad != aad:
            raise AuthenticationError("associated data mismatch")
        salt = b64u_decode(envelope["salt"])
        return AESGCM(_key(key, salt)).decrypt(b64u_decode(envelope["nonce"]), b64u_decode(envelope["ciphertext"]), aad)
    except (InvalidTag, KeyError, ValueError, TypeError) as exc:
        raise AuthenticationError("ciphertext authentication failed") from exc

def encrypt_json(value, key: bytes, aad: bytes = b"") -> dict[str, str]:
    return encrypt(canonical_json(value), key, aad)
