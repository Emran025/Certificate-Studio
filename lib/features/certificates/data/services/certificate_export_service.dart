import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/files/export_file_writer.dart';

enum CertificateExportBundleStyle { flat, perCertificate }

class CertificateExportService {
  CertificateExportService({
    CertificateArtifactStore? artifactStore,
    this.database,
  }) : artifactStore = artifactStore ?? CertificateArtifactStore();

  final CertificateArtifactStore artifactStore;
  final AppDatabase? database;

  Future<String?> exportSingle({
    required Map<String, Object?> certificate,
    required String extension,
    required String fileName,
  }) async {
    final reference = extension == 'pdf'
        ? certificate['file_path'] as String?
        : certificate['image_path'] as String?;
    if (reference == null || reference.isEmpty) return null;
    final bytes = await artifactStore.read(reference);
    if (bytes == null || bytes.isEmpty) return null;
    return saveExportBytes(
      dialogTitle: 'Export certificate',
      fileName: '$fileName.$extension',
      bytes: bytes,
      extension: extension,
    );
  }

  Future<String?> exportZip({
    required List<Map<String, Object?>> certificates,
    required String fileName,
    required Set<String> extensions,
    String Function(Map<String, Object?> certificate)? fileNameFor,
    CertificateExportBundleStyle style = CertificateExportBundleStyle.flat,
  }) async {
    final archive = Archive();
    for (final certificate in certificates) {
      final name = fileNameFor?.call(certificate) ??
          (certificate['id']?.toString() ?? 'certificate');
      final files = <ArchiveFile>[];
      for (final extension in extensions) {
        final reference = extension == 'pdf'
            ? certificate['file_path'] as String?
            : certificate['image_path'] as String?;
        if (reference == null || reference.isEmpty) continue;
        final bytes = await artifactStore.read(reference);
        if (bytes == null || bytes.isEmpty) continue;
        files.add(ArchiveFile('$name.$extension', bytes.length, bytes));
      }
      if (style == CertificateExportBundleStyle.perCertificate) {
        if (files.isEmpty) continue;
        final signature = await _signatureFor(certificate);
        files.add(ArchiveFile(
          '$name/signature.txt',
          signature.length,
          signature.codeUnits,
        ));
        final nested = Archive();
        for (final file in files) {
          nested.addFile(ArchiveFile(
            file.name.substring(file.name.indexOf('/') + 1),
            file.size,
            file.content,
          ));
        }
        final encoded = ZipEncoder().encode(nested);
        if (encoded != null && encoded.isNotEmpty) {
          archive.addFile(ArchiveFile('$name.zip', encoded.length, encoded));
        }
      } else {
        for (final file in files) {
          archive.addFile(file);
        }
      }
    }
    if (archive.files.isEmpty) return null;
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null || encoded.isEmpty) return null;
    return saveExportBytes(
      dialogTitle: 'Export certificates',
      fileName: '$fileName.zip',
      bytes: Uint8List.fromList(encoded),
      extension: 'zip',
    );
  }

  Future<String> _signatureFor(Map<String, Object?> certificate) async {
    final database = this.database;
    if (database == null) return '';
    final rows = await database.query(
      DatabaseTables.verificationRecords,
      where: {'certificate_id': certificate['id']},
      columns: ['signature', 'payload_json'],
    );
    if (rows.isEmpty) return '';
    final signature = rows.first['signature'];
    if (signature is String && signature.isNotEmpty) return signature;
    return '';
  }
}
