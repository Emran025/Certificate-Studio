import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'certificate.dart';
import 'encoding.dart';
import 'hash.dart';

const qrScheme = 'cstudio://verify/v2/';
const legacyQrScheme = 'cstudio://verify/v1/';

enum VerificationStatus { valid, invalidPayload, invalidDocument, invalidSignature }

class VerificationResult {
  const VerificationResult(this.status, {this.record});
  final VerificationStatus status;
  final Map<String, dynamic>? record;
  bool get isValid => status == VerificationStatus.valid;
}

String encodeVerificationQrPayload(Map<String, dynamic> record) {
  // Keep the standalone crypto API backwards compatible. Application-issued
  // certificate records contain fields and a public key and use compact v2;
  // minimal records continue to use the self-contained v1 payload.
  if (record['fields'] == null || record['public_key'] == null) {
    return '$legacyQrScheme${base64UrlEncodeNoPadding(canonicalJsonBytes(record))}';
  }
  final certificateId = Uri.encodeComponent(record['certificate_id']?.toString() ?? '');
  final projectId = Uri.encodeComponent(record['project_id']?.toString() ?? '');
  final documentHash = Uri.encodeComponent(record['document_hash']?.toString() ?? '');
  final signature = Uri.encodeComponent(record['signature']?.toString() ?? '');
  final fields = record['fields'];
  final values = fields is Map ? fields.values.take(2).toList() : const <dynamic>[];
  final firstValues = [
    for (var index = 0; index < 2; index++)
      Uri.encodeComponent(index < values.length ? '${values[index]}' : ''),
  ];
  return '$qrScheme$projectId/$certificateId/$documentHash/$signature/${firstValues.join('/')}';
}

Map<String, dynamic> decodeVerificationQrPayload(String payload) {
  if (payload.startsWith(qrScheme)) {
    final parts = payload.substring(qrScheme.length).split('/');
    if ((parts.length != 4 && parts.length != 6) ||
        parts.take(4).any((part) => part.isEmpty)) {
      throw const FormatException('malformed compact verification QR payload');
    }
    final record = <String, dynamic>{
      'format': certificateRecordFormat,
      'project_id': Uri.decodeComponent(parts[0]),
      'certificate_id': Uri.decodeComponent(parts[1]),
      'document_hash': Uri.decodeComponent(parts[2]),
      'signature': Uri.decodeComponent(parts[3]),
    };
    if (parts.length == 6) {
      record['_qr_first_values'] = [
        Uri.decodeComponent(parts[4]),
        Uri.decodeComponent(parts[5]),
      ];
    }
    return record;
  }
  if (!payload.startsWith(legacyQrScheme)) {
    throw const FormatException('unsupported verification QR payload');
  }
  final bytes = base64UrlDecode(payload.substring(legacyQrScheme.length));
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
