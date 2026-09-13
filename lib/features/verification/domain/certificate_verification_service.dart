import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/security/keys/institution_key_manager.dart';

enum CertificateVerificationStatus {
  valid,
  integrityCompromised,
  invalidSignature,
  unknownCertificate,
  unsupported,
  verificationDataMissing,
  failed,
}

class CertificateVerificationResult {
  const CertificateVerificationResult({
    required this.status,
    this.certificateId,
    this.recipient,
    this.institution,
    this.course,
    this.issueDate,
    this.hash,
    this.algorithm,
    this.protocolVersion,
    this.reason,
  });
  final CertificateVerificationStatus status;
  final String? certificateId;
  final String? recipient;
  final String? institution;
  final String? course;
  final String? issueDate;
  final String? hash;
  final String? algorithm;
  final String? protocolVersion;
  final String? reason;
  bool get isValid => status == CertificateVerificationStatus.valid;
}

class CertificateVerificationService {
  CertificateVerificationService(this.database, this.keyStorage);
  final AppDatabase database;
  final KeyStorage keyStorage;

  Future<CertificateVerificationResult> verify(String certificateId) async {
    try {
      final records = await database.query(DatabaseTables.verificationRecords, where: {'certificate_id': certificateId});
      if (records.isEmpty) return _result(CertificateVerificationStatus.unknownCertificate, certificateId: certificateId, reason: 'Certificate was not found in this offline workspace.');
      final record = _decode(records.first['payload_json']);
      final certificates = await database.query(DatabaseTables.certificates, where: {'id': certificateId});
      final document = certificates.isEmpty ? <int>[] : utf8.encode((certificates.first['document_json'] as String?) ?? '');
      var publicKey = _embeddedPublicKey(record);
      if (publicKey == null) {
        final stored = await keyStorage.read('project.${record['project_id']}.key');
        if (stored == null) return _fromRecord(record, CertificateVerificationStatus.verificationDataMissing, 'The certificate public key is unavailable on this device.');
        publicKey = (await CertificateKeyPair.fromSeed(_hexDecode(stored))).publicKey;
      }
      return _verifyRecord(record, document, publicKey);
    } catch (error) {
      return _result(CertificateVerificationStatus.failed, certificateId: certificateId, reason: 'Verification could not be completed: $error');
    }
  }

  Future<CertificateVerificationResult> verifyFile(List<int> bytes, {String? fileName}) async {
    try {
      final record = _extractRecord(bytes);
      if (record == null) return const CertificateVerificationResult(status: CertificateVerificationStatus.verificationDataMissing, reason: 'This certificate does not contain embedded verification data.');
      final publicKey = _embeddedPublicKey(record);
      if (publicKey == null) return _fromRecord(record, CertificateVerificationStatus.verificationDataMissing, 'The certificate public-key data is missing or unsupported.');
      return _verifyRecord(record, _documentFromRecord(record), publicKey);
    } on FormatException catch (error) {
      return _result(CertificateVerificationStatus.unsupported, reason: 'Unsupported or malformed certificate${fileName == null ? '' : ' ($fileName)'}: $error');
    } catch (error) {
      return _result(CertificateVerificationStatus.failed, reason: 'Verification failed: $error');
    }
  }

  Future<CertificateVerificationResult> verifyQr(String payload) async {
    try {
      final record = decodeVerificationQrPayload(payload.trim());
      final publicKey = _embeddedPublicKey(record);
      if (publicKey == null) return _fromRecord(record, CertificateVerificationStatus.verificationDataMissing, 'The QR payload does not contain a public key.');
      return _verifyRecord(record, _documentFromRecord(record), publicKey);
    } catch (_) {
      return const CertificateVerificationResult(status: CertificateVerificationStatus.unsupported, reason: 'The QR payload is malformed or uses an unsupported protocol.');
    }
  }

  Future<CertificateVerificationResult> _verifyRecord(Map<String, dynamic> record, List<int> document, SimplePublicKey publicKey) async {
    if (record['document_hash'] != await sha256Base64Url(document)) return _fromRecord(record, CertificateVerificationStatus.integrityCompromised, 'The certificate data was modified or does not match its embedded hash.');
    final valid = await verifyVerificationRecord(record, document, publicKey);
    return _fromRecord(record, valid ? CertificateVerificationStatus.valid : CertificateVerificationStatus.invalidSignature, valid ? null : 'The digital signature is invalid.');
  }

  List<int> _documentFromRecord(Map<String, dynamic> record) {
    final embedded = record['document_data'];
    if (embedded is String) return base64Url.decode(base64Url.normalize(embedded));
    return utf8.encode(jsonEncode({
    'project_id': record['project_id'],
    'student_id': record['student_id'],
    'fields': {
      'student_class': record['student_class'],
      'issue_date': record['issue_date'],
      if (record['student_name'] != null) 'student_name': record['student_name'],
      if (record['course'] != null) 'course': record['course'],
      if (record['course_name'] != null) 'course_name': record['course_name'],
    },
    }));
  }

  CertificateVerificationResult _fromRecord(Map<String, dynamic> record, CertificateVerificationStatus status, String? reason) {
    final fields = record['fields'] is Map ? Map<String, dynamic>.from(record['fields'] as Map) : record;
    return _result(status, certificateId: record['certificate_id']?.toString(), recipient: fields['recipient']?.toString() ?? fields['student_name']?.toString() ?? fields['name']?.toString(), institution: record['institution_id']?.toString(), course: fields['course_name']?.toString() ?? fields['course']?.toString(), issueDate: fields['issue_date']?.toString(), hash: record['document_hash']?.toString(), algorithm: 'Ed25519', protocolVersion: record['format']?.toString(), reason: reason);
  }

  CertificateVerificationResult _result(CertificateVerificationStatus status, {String? certificateId, String? recipient, String? institution, String? course, String? issueDate, String? hash, String? algorithm, String? protocolVersion, String? reason}) => CertificateVerificationResult(status: status, certificateId: certificateId, recipient: recipient, institution: institution, course: course, issueDate: issueDate, hash: hash, algorithm: algorithm, protocolVersion: protocolVersion, reason: reason);

  Map<String, dynamic>? _extractRecord(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    final match = RegExp(r'CSTUDIO_RECORD_V1:([A-Za-z0-9_-]+)').firstMatch(text);
    if (match == null) return null;
    final value = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(match.group(1)!))));
    if (value is! Map) throw const FormatException('embedded record is not an object');
    return Map<String, dynamic>.from(value);
  }

  SimplePublicKey? _embeddedPublicKey(Map<String, dynamic> record) {
    final value = record['public_key'];
    return value is Map ? publicKeyFromRecord(Map<String, dynamic>.from(value)) : null;
  }
  Map<String, dynamic> _decode(Object? raw) => raw is String ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : {};
  List<int> _hexDecode(String value) => [for (var i = 0; i < value.length; i += 2) int.parse(value.substring(i, i + 2), radix: 16)];
}
