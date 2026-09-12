import 'dart:convert';

import 'package:certificate_crypto/certificate_crypto.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_tables.dart';
import '../../../core/security/keys/institution_key_manager.dart';

class CertificateGenerationResult {
  const CertificateGenerationResult({
    required this.jobId,
    required this.status,
    required this.total,
    required this.generated,
    required this.failed,
    required this.errors,
  });

  final String jobId;
  final String status;
  final int total;
  final int generated;
  final int failed;
  final List<String> errors;
}

/// Generates the signed, structured certificate representation used by the
/// offline verifier. Each run is represented by a durable job and is safe to
/// repeat: a student receives one current certificate rather than duplicates.
class CertificateGenerationService {
  CertificateGenerationService(this.database, this.keyStorage);

  final AppDatabase database;
  final KeyStorage keyStorage;

  Future<CertificateGenerationResult> generate({
    required String projectId,
    required String institutionId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final students = await database.query(
      DatabaseTables.students,
      where: {'project_id': projectId},
    );
    final fields = await database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': projectId},
    );
    final jobId = 'generation-${projectId}-${DateTime.now().microsecondsSinceEpoch}';
    final startedAt = DateTime.now().toUtc().toIso8601String();
    await database.insert(DatabaseTables.generationJobs, {
      'id': jobId,
      'project_id': projectId,
      'status': students.isEmpty ? 'empty' : 'running',
      'total_count': students.length,
      'completed_count': 0,
      'failed_count': 0,
      'started_at': startedAt,
      'completed_at': students.isEmpty ? startedAt : null,
      'error_message': students.isEmpty ? 'No recipient data was imported.' : null,
    });

    if (students.isEmpty) {
      return CertificateGenerationResult(
        jobId: jobId,
        status: 'empty',
        total: 0,
        generated: 0,
        failed: 0,
        errors: const ['Import at least one recipient before generating certificates.'],
      );
    }

    final errors = <String>[];
    var generated = 0;
    final keyPair = await _keyPair(projectId);
    for (var index = 0; index < students.length; index++) {
      final student = students[index];
      final studentId = student['id']! as String;
      final itemId = '$jobId-item-$index';
      await database.insert(DatabaseTables.generationItems, {
        'id': itemId,
        'job_id': jobId,
        'student_id': studentId,
        'status': 'running',
      });
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
        final certificateId = 'certificate-$projectId-$studentId';
        final document = utf8.encode(jsonEncode({
          'project_id': projectId,
          'student_id': studentId,
          'fields': values,
        }));
        final record = await createVerificationRecord({
          'institution_id': institutionId,
          'project_id': projectId,
          'certificate_id': certificateId,
          ...values,
        }, document, keyPair.privateKey);
        final now = DateTime.now().toUtc().toIso8601String();
        final certificateValues = {
          'id': certificateId,
          'project_id': projectId,
          'student_id': studentId,
          'file_path': null,
          'image_path': null,
          'document_json': utf8.decode(document),
          'status': 'signed',
          'document_hash': record['document_hash'],
          'created_at': now,
          'updated_at': now,
        };
        final existing = await database.query(DatabaseTables.certificates, where: {'id': certificateId});
        if (existing.isEmpty) {
          await database.insert(DatabaseTables.certificates, certificateValues);
        } else {
          await database.update(DatabaseTables.certificates, certificateId, certificateValues);
        }
        final verificationId = 'verification-$certificateId';
        final verificationValues = {
          'id': verificationId,
          'certificate_id': certificateId,
          'institution_id': institutionId,
          'project_id': projectId,
          'payload_json': jsonEncode(record),
          'signature': record['signature'],
          'created_at': now,
        };
        final existingVerification = await database.query(DatabaseTables.verificationRecords, where: {'certificate_id': certificateId});
        if (existingVerification.isEmpty) {
          await database.insert(DatabaseTables.verificationRecords, verificationValues);
        } else {
          await database.update(DatabaseTables.verificationRecords, verificationId, verificationValues);
        }
        await database.update(DatabaseTables.generationItems, itemId, {
          'certificate_id': certificateId,
          'status': 'completed',
          'completed_at': now,
        });
        generated++;
      } catch (error) {
        final message = 'Row ${index + 1}: $error';
        errors.add(message);
        await database.update(DatabaseTables.generationItems, itemId, {
          'status': 'failed',
          'error_message': message,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      final completed = index + 1;
      await database.update(DatabaseTables.generationJobs, jobId, {
        'completed_count': completed,
        'failed_count': completed - generated,
      });
      onProgress?.call(completed, students.length);
    }
    final status = generated == students.length ? 'completed' : generated == 0 ? 'failed' : 'partial';
    final completedAt = DateTime.now().toUtc().toIso8601String();
    await database.update(DatabaseTables.generationJobs, jobId, {
      'status': status,
      'completed_at': completedAt,
      'error_message': errors.isEmpty ? null : errors.join('\n'),
    });
    return CertificateGenerationResult(
      jobId: jobId,
      status: status,
      total: students.length,
      generated: generated,
      failed: students.length - generated,
      errors: errors,
    );
  }

  Future<CertificateKeyPair> _keyPair(String projectId) async {
    final stored = await keyStorage.read('project.$projectId.key');
    final seed = stored == null ? generateMasterKey() : _hexDecode(stored);
    if (stored == null) await keyStorage.write('project.$projectId.key', seed.map((value) => value.toRadixString(16).padLeft(2, '0')).join());
    return CertificateKeyPair.fromSeed(seed);
  }

  List<int> _hexDecode(String value) => [for (var i = 0; i < value.length; i += 2) int.parse(value.substring(i, i + 2), radix: 16)];

  Map<String, dynamic> _decodeData(Object? raw) {
    if (raw is! String) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }
}
