import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'certificate.dart';
import 'encoding.dart';
import 'hash.dart';

const qrScheme = 'cstudio://verify/v1/';

enum VerificationStatus { valid, invalidPayload, invalidDocument, invalidSignature }

class VerificationResult {
  const VerificationResult(this.status, {this.record});
  final VerificationStatus status;
  final Map<String, dynamic>? record;
  bool get isValid => status == VerificationStatus.valid;
}

String encodeVerificationQrPayload(Map<String, dynamic> record) => '$qrScheme${base64UrlEncodeNoPadding(canonicalJsonBytes(record))}';

Map<String, dynamic> decodeVerificationQrPayload(String payload) {
  if (!payload.startsWith(qrScheme)) throw const FormatException('unsupported verification QR payload');
  final bytes = base64UrlDecode(payload.substring(qrScheme.length));
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map) throw const FormatException('verification QR payload must be an object');
  return Map<String, dynamic>.from(value);
}

Future<VerificationResult> verifyQrPayload(String payload, List<int> document, SimplePublicKey publicKey) async {
  try {
    final record = decodeVerificationQrPayload(payload);
    if (record['document_hash'] != await sha256Base64Url(document)) return VerificationResult(VerificationStatus.invalidDocument, record: record);
    if (!await verifyVerificationRecord(record, document, publicKey)) return VerificationResult(VerificationStatus.invalidSignature, record: record);
    return VerificationResult(VerificationStatus.valid, record: record);
  } on FormatException {
    return const VerificationResult(VerificationStatus.invalidPayload);
  } on ArgumentError {
    return const VerificationResult(VerificationStatus.invalidPayload);
  }
}
