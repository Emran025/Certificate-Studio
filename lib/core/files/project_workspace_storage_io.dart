import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> ensureProjectWorkspace(String projectId) async {
  final root = await _root(projectId);
  for (final relative in [
    'assets/templates',
    'assets/fonts',
    'assets/logos',
    'data',
    'design',
    'outputs/certificates',
    'verification',
  ]) {
    await Directory(_join(root.path, relative)).create(recursive: true);
  }
}

Future<String?> saveProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
  required List<int> bytes,
}) async {
  final file = await _file(projectId, relativePath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<List<int>?> readProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) async {
  final file = await _file(projectId, relativePath);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<void> deleteProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) async {
  final file = await _file(projectId, relativePath);
  if (await file.exists()) await file.delete();
}

Future<void> deleteProjectWorkspace(String projectId) async {
  final root = await _root(projectId);
  if (await root.exists()) await root.delete(recursive: true);
}

Future<Directory> _root(String projectId) async {
  final safeId = base64Url.encode(utf8.encode(projectId)).replaceAll('=', '');
  final support = await getApplicationSupportDirectory();
  return Directory(
    _join(_join(support.path, 'CertificateStudio/workspaces'), safeId),
  );
}

Future<File> _file(String projectId, String relativePath) async {
  final segments = _validatedSegments(relativePath);
  final root = await _root(projectId);
  return File(_join(root.path, segments.join(Platform.pathSeparator)));
}

List<String> _validatedSegments(String path) {
  if (path.isEmpty || path.startsWith('/') || path.contains('\\')) {
    throw ArgumentError.value(path, 'relativePath', 'Unsafe workspace path.');
  }
  final segments = path.split('/');
  if (segments.any(
    (segment) =>
        segment.isEmpty ||
        segment == '.' ||
        segment == '..' ||
        !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(segment),
  )) {
    throw ArgumentError.value(path, 'relativePath', 'Unsafe workspace path.');
  }
  return segments;
}

String _join(String base, String relative) =>
    '$base${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
