part of '../certificate_library_screen.dart';

class _ArtifactImage extends StatelessWidget {
  const _ArtifactImage({required this.reference, this.fit = BoxFit.contain});
  final String? reference;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (reference == null) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 42),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: SharedPreferencesCertificateArtifactStore().read(reference!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        return bytes == null
            ? const Center(
                child: Icon(Icons.image_not_supported_outlined, size: 42),
              )
            : Image.memory(
                bytes,
                fit: fit,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
              );
      },
    );
  }
}

Map<String, Object?> _exportRow(_LibraryCertificate certificate) => {
  'id': certificate.id,
  'project_id': certificate.projectId,
  'record_id': certificate.recordId,
  'file_path': certificate.pdfReference,
  'image_path': certificate.imageReference,
  'document_hash': certificate.documentHash,
};
