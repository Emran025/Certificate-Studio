import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/security/keys/institution_key_manager.dart';

class CertificateGenerationResult {
  const CertificateGenerationResult({required this.total, required this.generated, required this.failed, required this.errors});
  final int total;
  final int generated;
  final int failed;
  final List<String> errors;
}

class CertificateGenerationService {
  CertificateGenerationService(this.database, this.keyStorage);
  final AppDatabase database;
  final KeyStorage keyStorage;

  Future<CertificateGenerationResult> generate({required String projectId, required String institutionId, void Function(int completed, int total)? onProgress}) async {
    final students = await database.query(DatabaseTables.students, where: {'project_id': projectId});
    final fields = await database.query(DatabaseTables.certificateFields, where: {'project_id': projectId});
    final errors = <String>[];
    var generated = 0;
    final total = students.length;
    final keyPair = await _keyPair(projectId);
    for (var index = 0; index < students.length; index++) {
      final student = students[index];
      try {
        final data = _decodeData(student['data_json']);
        final values = <String, dynamic>{
          'student_class': student['class_name'] ?? '${index + 1}',
          'issue_date': DateTime.now().toUtc().toIso8601String().split('T').first,
          ...data,
        };
        for (final field in fields) {
          final source = field['source'] as String?;
          final className = field['class_name'] as String?;
          if (source != null && className != null) values[className] = data[source] ?? '';
        }
        final certificateId = 'certificate-${DateTime.now().microsecondsSinceEpoch}-$index';
        final document = utf8.encode(jsonEncode({'project_id': projectId, 'student_id': student['id'], 'fields': values}));
        final record = await createVerificationRecord({'institution_id': institutionId, 'project_id': projectId, 'certificate_id': certificateId, ...values}, document, keyPair.privateKey);
        final now = DateTime.now().toUtc().toIso8601String();
        await database.insert(DatabaseTables.certificates, {'id': certificateId, 'project_id': projectId, 'student_id': student['id'], 'file_path': null, 'image_path': null, 'status': 'signed', 'document_hash': record['document_hash'], 'created_at': now, 'updated_at': now});
        await database.insert(DatabaseTables.verificationRecords, {'id': 'verification-$certificateId', 'certificate_id': certificateId, 'institution_id': institutionId, 'project_id': projectId, 'payload_json': jsonEncode(record), 'signature': record['signature'], 'created_at': now});
        generated++;
      } catch (error) {
        errors.add('Row ${index + 1}: $error');
      }
      onProgress?.call(index + 1, total);
    }
    return CertificateGenerationResult(total: total, generated: generated, failed: total - generated, errors: errors);
  }

  Future<CertificateKeyPair> _keyPair(String projectId) async {
    final stored = await keyStorage.read('project.$projectId.key');
    final seed = stored == null ? generateMasterKey() : _hexDecode(stored);
    if (stored == null) await keyStorage.write('project.$projectId.key', seed.map((value) => value.toRadixString(16).padLeft(2, '0')).join());
    return CertificateKeyPair.fromSeed(seed);
  }

  List<int> _hexDecode(String value) => [for (var i = 0; i < value.length; i += 2) int.parse(value.substring(i, i + 2), radix: 16)];
  Map<String, dynamic> _decodeData(Object? raw) { if (raw is! String) return {}; final value = jsonDecode(raw); return value is Map ? Map<String, dynamic>.from(value) : {}; }
}
