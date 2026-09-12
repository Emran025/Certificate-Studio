import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'encoding.dart';

const keyFormat = 'certificate-crypto-key-v1';

class CertificateKeyPair {
  CertificateKeyPair(this.privateKey, this.publicKey);
  final SimpleKeyPair privateKey;
  final SimplePublicKey publicKey;

  static Future<CertificateKeyPair> generate() async {
    final pair = await Ed25519().newKeyPair();
    return fromPair(pair);
  }

  static Future<CertificateKeyPair> fromSeed(List<int> seed) async {
    if (seed.length != 32) throw ArgumentError('Ed25519 seed must be 32 bytes');
    return fromPair(await Ed25519().newKeyPairFromSeed(seed));
  }

  static Future<CertificateKeyPair> fromPair(SimpleKeyPair pair) async {
    final publicKey = await pair.extractPublicKey();
    return CertificateKeyPair(pair, publicKey);
  }

  Future<List<int>> privateBytes() => privateKey.extractPrivateKeyBytes();
  List<int> publicBytes() => publicKey.bytes;
  Map<String, String> publicRecord() => {'format': keyFormat, 'algorithm': 'Ed25519', 'public_key': base64UrlEncodeNoPadding(publicBytes())};
}

SimplePublicKey publicKeyFromRecord(Map<String, dynamic> record) {
  if (record['format'] != keyFormat || record['algorithm'] != 'Ed25519') throw FormatException('unsupported public key record');
  final bytes = base64UrlDecode(record['public_key'] as String);
  if (bytes.length != 32) throw FormatException('invalid Ed25519 public key');
  return SimplePublicKey(bytes, type: KeyPairType.ed25519);
}

List<int> generateMasterKey() => List<int>.generate(32, (_) => Random.secure().nextInt(256));

Future<List<int>> deriveProjectKey(List<int> institutionKey, String projectId) async {
  if (institutionKey.length != 32 || projectId.isEmpty) throw ArgumentError('invalid institution key or project id');
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final derived = await hkdf.deriveKey(secretKey: SecretKey(institutionKey), info: utf8Bytes('Certificate Studio project key v1:$projectId'));
  return derived.extractBytes();
}

List<int> utf8Bytes(String value) => utf8.encode(value);
