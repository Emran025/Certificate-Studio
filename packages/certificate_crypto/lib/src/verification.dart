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

// QR payloads are byte-sensitive: the cryptographic values remain unchanged,
// while verbose JSON property names are replaced with one-character aliases.
// This typically removes an entire QR version for certificate records without
// changing the decoded record or the signature being verified.
const _qrKeyAliases = <String, String>{
  'institution_id': 'i',
  'project_id': 'p',
  'certificate_id': 'c',
  'public_key': 'k',
  'fields': 'f',
  'document_hash': 'h',
  'signature': 's',
};

String encodeVerificationQrPayload(Map<String, dynamic> record) {
  final compact = <String, dynamic>{
    for (final entry in record.entries)
      (_qrKeyAliases[entry.key] ?? entry.key): entry.value,
  };
  return '$qrScheme${base64UrlEncodeNoPadding(canonicalJsonBytes(compact))}';
}

Map<String, dynamic> decodeVerificationQrPayload(String payload) {
  if (!payload.startsWith(qrScheme)) throw const FormatException('unsupported verification QR payload');
  final bytes = base64UrlDecode(payload.substring(qrScheme.length));
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map) throw const FormatException('verification QR payload must be an object');
  final aliases = _qrKeyAliases.map((key, value) => MapEntry(value, key));
  return Map<String, dynamic>.fromEntries(
    (value as Map).entries.map(
      (entry) => MapEntry(
        aliases[entry.key.toString()] ?? entry.key.toString(),
        entry.value,
      ),
    ),
  );
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
