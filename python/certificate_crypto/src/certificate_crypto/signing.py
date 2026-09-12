"""Ed25519 signing over exact bytes; callers choose the canonical payload."""
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from .exceptions import AuthenticationError
from .serialization import b64u_encode, b64u_decode

def sign(data: bytes, private_key: Ed25519PrivateKey) -> bytes:
    return private_key.sign(data)

def sign_b64(data: bytes, private_key: Ed25519PrivateKey) -> str:
    return b64u_encode(sign(data, private_key))

def verify(data: bytes, signature: bytes | str, public_key) -> bool:
    try:
        public_key.verify(b64u_decode(signature) if isinstance(signature, str) else signature, data)
        return True
    except (InvalidSignature, ValueError, TypeError):
        return False

def require_verify(data: bytes, signature: bytes | str, public_key) -> None:
    if not verify(data, signature, public_key):
        raise AuthenticationError("invalid digital signature")
