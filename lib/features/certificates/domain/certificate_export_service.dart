import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/files/certificate_artifact_store.dart';
import '../../../core/files/export_file_writer.dart';

class CertificateExportService {
  CertificateExportService({CertificateArtifactStore? artifactStore})
      : artifactStore = artifactStore ?? CertificateArtifactStore();

  final CertificateArtifactStore artifactStore;

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
    required String extension,
    String Function(Map<String, Object?> certificate)? fileNameFor,
  }) async {
    final archive = Archive();
    for (final certificate in certificates) {
      final reference = extension == 'pdf'
          ? certificate['file_path'] as String?
          : certificate['image_path'] as String?;
      if (reference == null || reference.isEmpty) continue;
      final bytes = await artifactStore.read(reference);
      if (bytes == null || bytes.isEmpty) continue;
      final name = fileNameFor?.call(certificate) ??
          (certificate['id']?.toString() ?? 'certificate');
      archive.addFile(ArchiveFile('$name.$extension', bytes.length, bytes));
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
}
