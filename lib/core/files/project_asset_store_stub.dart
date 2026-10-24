import 'dart:convert';

Future<String?> saveProjectBackground({
  required String projectId,
  required String fileName,
  required List<int> bytes,
}) async {
  final extension = fileName.split('.').last.toLowerCase();
  final mimeType = switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}
