import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/security/keys/institution_key_manager.dart';

class CertificateVerificationResult {
  const CertificateVerificationResult({required this.isValid, required this.certificateId, this.studentClass, this.course, this.reason});
  final bool isValid;
  final String? certificateId;
  final String? studentClass;
  final String? course;
  final String? reason;
}

class CertificateVerificationService {
  CertificateVerificationService(this.database, this.keyStorage);
  final AppDatabase database;
  final KeyStorage keyStorage;

  Future<CertificateVerificationResult> verify(String certificateId) async {
    try {
      final certificates = await database.query(DatabaseTables.certificates, where: {'id': certificateId});
      if (certificates.isEmpty) return const CertificateVerificationResult(isValid: false, certificateId: null, reason: 'Certificate was not found in this offline workspace.');
      final certificate = certificates.first;
      final records = await database.query(DatabaseTables.verificationRecords, where: {'certificate_id': certificateId});
      if (records.isEmpty) return CertificateVerificationResult(isValid: false, certificateId: certificateId, reason: 'No verification record is associated with this certificate.');
      final record = _decode(records.first['payload_json']);
      final document = utf8.encode((certificate['document_json'] as String?) ?? '');
      final key = await keyStorage.read('project.${certificate['project_id']}.key');
      if (key == null) return CertificateVerificationResult(isValid: false, certificateId: certificateId, reason: 'The project verification key is unavailable on this device.');
      final keyPair = await CertificateKeyPair.fromSeed(_hexDecode(key));
      final valid = await verifyVerificationRecord(record, document, keyPair.publicKey);
      return CertificateVerificationResult(isValid: valid, certificateId: certificateId, studentClass: record['student_class']?.toString(), course: record['course']?.toString(), reason: valid ? null : 'The document hash or digital signature did not match.');
    } catch (error) {
      return CertificateVerificationResult(isValid: false, certificateId: certificateId, reason: 'Verification could not be completed: $error');
    }
  }

  Map<String, dynamic> _decode(Object? raw) { if (raw is! String) return {}; final value = jsonDecode(raw); return value is Map ? Map<String, dynamic>.from(value) : {}; }
  List<int> _hexDecode(String value) => [for (var i = 0; i < value.length; i += 2) int.parse(value.substring(i, i + 2), radix: 16)];
}
