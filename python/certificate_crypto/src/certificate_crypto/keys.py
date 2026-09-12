"""Ed25519 key handling and deterministic project-key derivation."""
import os
from dataclasses import dataclass
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from .exceptions import InvalidKeyError
from .serialization import b64u_encode, b64u_decode, canonical_json

KEY_FORMAT = "certificate-crypto-key-v1"

@dataclass(frozen=True)
class KeyPair:
    private_key: Ed25519PrivateKey
    public_key: Ed25519PublicKey

    @classmethod
    def generate(cls) -> "KeyPair":
        private = Ed25519PrivateKey.generate()
        return cls(private, private.public_key())

    @classmethod
    def from_private_bytes(cls, seed: bytes) -> "KeyPair":
        if len(seed) != 32:
            raise InvalidKeyError("Ed25519 private seed must be 32 bytes")
        private = Ed25519PrivateKey.from_private_bytes(seed)
        return cls(private, private.public_key())

    @classmethod
    def from_public_bytes(cls, value: bytes) -> "KeyPair":
        raise InvalidKeyError("a public key cannot form a signing key pair")

    def private_bytes(self) -> bytes:
        return self.private_key.private_bytes(serialization.Encoding.Raw, serialization.PrivateFormat.Raw, serialization.NoEncryption())

    def public_bytes(self) -> bytes:
        return self.public_key.public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)

    def public_record(self) -> dict[str, str]:
        return {"format": KEY_FORMAT, "algorithm": "Ed25519", "public_key": b64u_encode(self.public_bytes())}

    def private_record(self, passphrase: str) -> dict[str, str]:
        from .encryption import encrypt
        if not isinstance(passphrase, str) or not passphrase:
            raise ValueError("a non-empty passphrase is required")
        envelope = encrypt(self.private_bytes(), passphrase.encode("utf-8"), aad=canonical_json({"purpose": "private-key", "algorithm": "Ed25519"}))
        return {"format": KEY_FORMAT, "algorithm": "Ed25519", "private_key": envelope}

    @classmethod
    def from_private_record(cls, record: dict[str, str], passphrase: str) -> "KeyPair":
        from .encryption import decrypt
        if record.get("format") != KEY_FORMAT or record.get("algorithm") != "Ed25519":
            raise InvalidKeyError("unsupported private key record")
        try:
            seed = decrypt(record["private_key"], passphrase.encode("utf-8"), aad=canonical_json({"purpose": "private-key", "algorithm": "Ed25519"}))
            return cls.from_private_bytes(seed)
        except Exception as exc:
            raise InvalidKeyError("unable to unlock private key") from exc

def load_public_key(record: dict[str, str] | bytes) -> Ed25519PublicKey:
    try:
        value = record if isinstance(record, bytes) else b64u_decode(record["public_key"])
        return Ed25519PublicKey.from_public_bytes(value)
    except Exception as exc:
        raise InvalidKeyError("invalid Ed25519 public key") from exc

def generate_master_key() -> bytes:
    return os.urandom(32)

def derive_project_key(institution_key: bytes, project_id: str) -> bytes:
    if len(institution_key) != 32 or not project_id:
        raise InvalidKeyError("institution key must be 32 bytes and project_id non-empty")
    return HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"Certificate Studio project key v1:" + project_id.encode("utf-8")).derive(institution_key)

def project_signing_key(institution_key: bytes, project_id: str) -> KeyPair:
    return KeyPair.from_private_bytes(derive_project_key(institution_key, project_id))
