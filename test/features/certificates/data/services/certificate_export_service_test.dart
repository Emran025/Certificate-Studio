import 'dart:typed_data';

import 'package:certificate_studio/core/files/certificate_artifact_store.dart';
import 'package:certificate_studio/features/certificates/data/services/certificate_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeArtifactStore implements CertificateArtifactStore {
  FakeArtifactStore(this.values);
  final Map<String, List<int>> values;

  @override
  Future<void> delete(String path) async {
    values.remove(path);
  }

  @override
  Future<Uint8List?> read(String path) async {
    final bytes = values[path];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<String> save({
    required String certificateId,
    required String extension,
    required List<int> bytes,
  }) async {
    final path = 'fake://$certificateId.$extension';
    values[path] = bytes;
    return path;
  }
}

void main() {
  test(
    'exportSingle returns null when certificate has no artifact reference',
    () async {
      final service = CertificateExportService(
        artifactStore: FakeArtifactStore({}),
      );

      final result = await service.exportSingle(
        certificate: const {'id': 'cert-1'},
        extension: 'pdf',
        fileName: 'certificate',
      );

      expect(result, isNull);
    },
  );

  test(
    'exportZip returns null when all requested artifacts are missing',
    () async {
      final service = CertificateExportService(
        artifactStore: FakeArtifactStore({}),
      );

      final result = await service.exportZip(
        certificates: const [
          {'id': 'cert-1', 'file_path': 'missing.pdf'},
        ],
        fileName: 'certificates',
        extensions: {'pdf'},
      );

      expect(result, isNull);
    },
  );
}
