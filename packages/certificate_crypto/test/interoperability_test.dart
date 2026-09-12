import 'dart:convert';
import 'package:test/test.dart';
import 'package:certificate_crypto/certificate_crypto.dart';

void main() {
  test('canonical JSON and SHA-256 match Python reference vector', () async {
    final value = {'z': 1, 'message': 'شهادة', 'a': [true, null]};
    expect(canonicalJson(value), '{"a":[true,null],"message":"شهادة","z":1}');
    expect(await sha256Base64Url(utf8.encode(canonicalJson(value))), 'TJHMIOlQaaJ72m22KvhnTXvawxJNMM_d6pYT9PhKKaE');
  });

  test('Python-compatible deterministic Ed25519 signing and verification', () async {
    final pair = await CertificateKeyPair.fromSeed(List<int>.generate(32, (i) => i));
    final signature = await signBytes(utf8.encode('certificate bytes'), pair.privateKey);
    expect(signature.length, 64);
    expect(await verifyBytes(utf8.encode('certificate bytes'), signature, pair.publicKey), isTrue);
    expect(await verifyBytes(utf8.encode('tampered'), signature, pair.publicKey), isFalse);
  });

  test('certificate record round trip and tamper rejection', () async {
    final pair = await CertificateKeyPair.fromSeed(List<int>.generate(32, (i) => i));
    final record = await createVerificationRecord({'institution_id': 'i', 'project_id': 'p', 'certificate_id': 'c'}, utf8.encode('rendered certificate'), pair.privateKey);
    expect(await verifyVerificationRecord(record, utf8.encode('rendered certificate'), pair.publicKey), isTrue);
    expect(await verifyVerificationRecord(record, utf8.encode('modified'), pair.publicKey), isFalse);
  });

  test('AES-GCM round trip and authentication failure', () async {
    final key = List<int>.filled(32, 7);
    final aad = utf8.encode('project-package-v1');
    final envelope = await encryptBytes(utf8.encode('secret'), key, aad: aad);
    expect(await decryptBytes(envelope, key, aad: aad), utf8.encode('secret'));
    final changed = Map<String, dynamic>.from(envelope)..['ciphertext'] = '${envelope['ciphertext']}A';
    expect(() => decryptBytes(changed, key, aad: aad), throwsA(anything));
  });

  test('versioned QR payload round trip and tamper rejection', () async {
    final pair = await CertificateKeyPair.fromSeed(List<int>.generate(32, (i) => i));
    final document = utf8.encode('qr certificate');
    final record = await createVerificationRecord({'institution_id': 'i', 'project_id': 'p', 'certificate_id': 'c'}, document, pair.privateKey);
    final payload = encodeVerificationQrPayload(record);
    expect(payload.startsWith(qrScheme), isTrue);
    expect(await verifyQrPayload(payload, document, pair.publicKey), predicate<VerificationResult>((result) => result.isValid));
    expect((await verifyQrPayload(payload, utf8.encode('changed'), pair.publicKey)).status, VerificationStatus.invalidDocument);
    expect(() => decodeVerificationQrPayload(payload.replaceFirst(qrScheme, 'https://invalid/')), throwsFormatException);
  });
}
