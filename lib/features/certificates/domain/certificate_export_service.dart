import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/files/certificate_artifact_store.dart';

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
    return FilePicker.platform.saveFile(
      dialogTitle: 'Export certificate',
      fileName: '$fileName.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
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
    return FilePicker.platform.saveFile(
      dialogTitle: 'Export certificates',
      fileName: '$fileName.zip',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: Uint8List.fromList(encoded),
    );
  }
}
