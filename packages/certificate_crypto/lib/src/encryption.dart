import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'encoding.dart';

const envelopeFormat = 'certificate-crypto-envelope-v1';

Future<Map<String, String>> encryptBytes(List<int> plaintext, List<int> key, {List<int> aad = const []}) async {
  if (key.length != 32) throw ArgumentError('AES-256 key must be 32 bytes');
  final algorithm = AesGcm.with256bits();
  final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
  final box = await algorithm.encrypt(plaintext, secretKey: SecretKey(key), nonce: nonce, aad: aad);
  return {
    'format': envelopeFormat,
    'algorithm': 'AES-256-GCM',
    'kdf': 'raw',
    'salt': '',
    'nonce': base64UrlEncodeNoPadding(box.nonce),
    'ciphertext': base64UrlEncodeNoPadding([...box.cipherText, ...box.mac.bytes]),
    'aad': base64UrlEncodeNoPadding(aad),
  };
}

Future<List<int>> decryptBytes(Map<String, dynamic> envelope, List<int> key, {List<int> aad = const []}) async {
  if (key.length != 32) throw ArgumentError('AES-256 key must be 32 bytes');
  if (envelope['format'] != envelopeFormat || envelope['algorithm'] != 'AES-256-GCM' || envelope['kdf'] != 'raw') throw FormatException('unsupported encryption envelope');
  final encodedAad = base64UrlDecode(envelope['aad'] as String);
  if (base64Encode(encodedAad) != base64Encode(aad)) throw StateError('associated data mismatch');
  final combined = base64UrlDecode(envelope['ciphertext'] as String);
  if (combined.length < 16) throw FormatException('invalid AES-GCM ciphertext');
  final box = SecretBox(combined.sublist(0, combined.length - 16), nonce: base64UrlDecode(envelope['nonce'] as String), mac: Mac(combined.sublist(combined.length - 16)));
  return AesGcm.with256bits().decrypt(box, secretKey: SecretKey(key), aad: aad);
}

Future<Map<String, dynamic>> encryptJson(Object value, List<int> key, {List<int> aad = const []}) => encryptBytes(utf8.encode(canonicalJson(value)), key, aad: aad);
