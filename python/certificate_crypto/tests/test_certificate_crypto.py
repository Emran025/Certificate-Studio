import hashlib
import json
import pytest
from cryptography.hazmat.primitives import serialization
from certificate_crypto import (
    AuthenticationError, KeyPair, canonical_json, create_record, decrypt, derive_project_key,
    encrypt, generate_master_key, hash_bytes, hash_json_b64, load_public_key, project_signing_key,
    sign, verify, verify_hash, verify_record,
)


def test_canonical_json_and_hash_vector():
    value = {"z": 1, "message": "شهادة", "a": [True, None]}
    expected = '{"a":[true,null],"message":"شهادة","z":1}'.encode("utf-8")
    assert canonical_json(value) == expected
    assert hash_bytes(expected) == hashlib.sha256(expected).digest()
    assert hash_json_b64(value)


def test_key_generation_public_and_encrypted_private_round_trip():
    pair = KeyPair.generate()
    public_record = pair.public_record()
    restored_public = load_public_key(public_record)
    assert restored_public.public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw) == pair.public_bytes()
    private_record = pair.private_record("correct horse battery staple")
    assert pair.public_bytes().hex() not in json.dumps(private_record)
    restored = KeyPair.from_private_record(private_record, "correct horse battery staple")
    assert restored.public_bytes() == pair.public_bytes()
    with pytest.raises(Exception):
        KeyPair.from_private_record(private_record, "wrong")


def test_signing_and_invalid_signature_cases():
    pair = KeyPair.generate()
    data = b"certificate bytes"
    signature = sign(data, pair.private_key)
    assert verify(data, signature, pair.public_key)
    assert not verify(data + b"!", signature, pair.public_key)
    altered = bytearray(signature)
    altered[0] ^= 1
    assert not verify(data, bytes(altered), pair.public_key)
    assert not verify(data, signature, KeyPair.generate().public_key)


def test_hash_integrity_failures():
    data = b"immutable certificate"
    digest = hash_bytes(data)
    assert verify_hash(data, digest)
    assert verify_hash(data, digest.hex())
    assert not verify_hash(data + b"tampered", digest)


def test_aes_gcm_encryption_raw_key_and_aad():
    key = generate_master_key()
    aad = b"project-package-v1"
    envelope = encrypt(b"secret project metadata", key, aad)
    assert decrypt(envelope, key, aad) == b"secret project metadata"
    with pytest.raises(AuthenticationError):
        decrypt(envelope, key, b"wrong-aad")
    modified = dict(envelope)
    modified["ciphertext"] = modified["ciphertext"][:-1] + ("A" if modified["ciphertext"][-1] != "A" else "B")
    with pytest.raises(AuthenticationError):
        decrypt(modified, key, aad)


def test_passphrase_encryption_uses_scrypt_and_round_trips():
    envelope = encrypt(b"private seed", b"a strong passphrase")
    assert envelope["kdf"] == "scrypt"
    assert decrypt(envelope, b"a strong passphrase") == b"private seed"
    with pytest.raises(AuthenticationError):
        decrypt(envelope, b"another passphrase")


def test_project_derivation_is_deterministic_and_domain_separated():
    master = bytes(range(32))
    assert derive_project_key(master, "project-a") == derive_project_key(master, "project-a")
    assert derive_project_key(master, "project-a") != derive_project_key(master, "project-b")
    pair = project_signing_key(master, "project-a")
    assert verify(b"hello", sign(b"hello", pair.private_key), pair.public_key)


def test_certificate_record_signs_hash_and_rejects_tampering():
    pair = KeyPair.generate()
    document = b"rendered PNG or PDF bytes"
    record = create_record({
        "institution_id": "institution-1", "project_id": "project-1", "certificate_id": "A001",
        "student_class": "A001", "course": "Flutter", "issue_date": "2026-09-12",
    }, document, pair.private_key)
    assert verify_record(record, document, pair.public_key)
    assert not verify_record(record, document + b"tamper", pair.public_key)
    changed = dict(record)
    changed["course"] = "Other"
    assert not verify_record(changed, document, pair.public_key)
    assert not verify_record(record, document, KeyPair.generate().public_key)
