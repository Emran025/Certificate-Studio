import 'package:cryptography/cryptography.dart';
import 'encoding.dart';
import 'hash.dart';
import 'signing.dart';

const certificateRecordFormat = 'certificate-verification-v1';

Future<Map<String, dynamic>> createVerificationRecord(Map<String, dynamic> fields, List<int> document, SimpleKeyPair keyPair) async {
  final record = Map<String, dynamic>.from(fields);
  for (final field in ['institution_id', 'project_id', 'certificate_id']) {
    if (record[field] is! String || (record[field] as String).isEmpty) throw ArgumentError('$field is required');
  }
  record['format'] = certificateRecordFormat;
  record['document_hash'] = await sha256Base64Url(document);
  // Keep the exact canonical document used for signing. Verification must
  // never guess field names or reconstruct a document from business labels.
  record['document_data'] = base64UrlEncodeNoPadding(document);
  record['signature'] = signatureBase64Url(await signBytes(canonicalJsonBytes(record), keyPair));
  return record;
}

Future<bool> verifyVerificationRecord(Map<String, dynamic> record, List<int> document, SimplePublicKey publicKey) async {
  try {
    if (record['format'] != certificateRecordFormat) return false;
    for (final field in ['institution_id', 'project_id', 'certificate_id']) {
      if (record[field] is! String || (record[field] as String).isEmpty) return false;
    }
    final unsigned = Map<String, dynamic>.from(record)..remove('signature');
    return unsigned['document_hash'] == await sha256Base64Url(document) && await verifyBytes(canonicalJsonBytes(unsigned), base64UrlDecode(record['signature'] as String), publicKey);
  } catch (_) {
    return false;
  }
}
