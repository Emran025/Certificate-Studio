# Certificate Crypto

`certificate-crypto` is the offline Python reference implementation for Certificate Studio's certificate security protocol. It is **not** a Flutter runtime dependency.

## Protocol

- **Canonical serialization:** JSON encoded as UTF-8, sorted keys, compact separators, and `ensure_ascii=false`; all signatures and structured hashes operate on these exact bytes.
- **Integrity:** SHA-256 (`hash_bytes`, `hash_json_b64`).
- **Authenticity:** Ed25519 signatures over exact bytes. Verification requires a trusted public key.
- **Confidentiality:** AES-256-GCM with a 96-bit random nonce. Passphrases use scrypt (N=32768, r=8, p=1); raw 32-byte keys use HKDF-derived/secret key material directly.
- **Hierarchy:** a 32-byte institution master secret derives a deterministic 32-byte project signing seed via HKDF-SHA256 with info `Certificate Studio project key v1:<project_id>`.
- **Key handling:** public records are portable; private key records are always encrypted with AES-GCM and a passphrase. Private keys are never emitted as plaintext by serialization helpers.

The JSON formats are versioned (`certificate-crypto-key-v1`, `certificate-crypto-envelope-v1`, and `certificate-verification-v1`) to prevent silent protocol drift.

```python
from certificate_crypto import KeyPair, create_record, verify_record

issuer = KeyPair.generate()
record = create_record({"institution_id": "uni", "project_id": "course", "certificate_id": "A001"}, b"rendered certificate", issuer.private_key)
assert verify_record(record, b"rendered certificate", issuer.public_key)
```
