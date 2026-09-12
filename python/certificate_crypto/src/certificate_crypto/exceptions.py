class CertificateCryptoError(Exception):
    """Base error for the reference cryptography package."""

class InvalidKeyError(CertificateCryptoError, ValueError):
    pass

class InvalidEnvelopeError(CertificateCryptoError, ValueError):
    pass

class AuthenticationError(CertificateCryptoError, ValueError):
    pass
