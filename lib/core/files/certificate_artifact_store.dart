import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'project_workspace_storage.dart';

abstract interface class CertificateArtifactStore {
  Future<String> save({
    required String projectId,
    required String certificateId,
    required String extension,
    required List<int> bytes,
  });
  Future<Uint8List?> read(String reference);
  Future<void> delete(String reference);
}

/// Legacy compatibility store for artifacts previously kept as base64 in prefs.
class SharedPreferencesCertificateArtifactStore
    implements CertificateArtifactStore {
  SharedPreferencesCertificateArtifactStore({this.preferences});
  SharedPreferences? preferences;

  @override
  Future<String> save({
    required String projectId,
    required String certificateId,
    required String extension,
    required List<int> bytes,
  }) async {
    final store = preferences ??= await SharedPreferences.getInstance();
    final reference = 'artifact://certificates/$certificateId.$extension';
    await store.setString(_key(reference), base64Encode(bytes));
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async {
    final store = preferences ??= await SharedPreferences.getInstance();
    final encoded = store.getString(_key(reference));
    return encoded == null ? null : Uint8List.fromList(base64Decode(encoded));
  }

  @override
  Future<void> delete(String reference) async {
    final store = preferences ??= await SharedPreferences.getInstance();
    await store.remove(_key(reference));
  }

  String _key(String reference) => 'certificate_artifact:$reference';
}

/// Stores new outputs in a project-scoped folder and transparently reads old
/// SharedPreferences references so existing certificates remain available.
class WorkspaceCertificateArtifactStore implements CertificateArtifactStore {
  WorkspaceCertificateArtifactStore({CertificateArtifactStore? legacyStore})
    : _legacyStore = legacyStore ?? SharedPreferencesCertificateArtifactStore();

  final CertificateArtifactStore _legacyStore;

  @override
  Future<String> save({
    required String projectId,
    required String certificateId,
    required String extension,
    required List<int> bytes,
  }) async {
    final normalizedExtension = extension.toLowerCase();
    if (!RegExp(r'^[a-z0-9]{1,8}$').hasMatch(normalizedExtension)) {
      throw ArgumentError.value(extension, 'extension');
    }
    final projectToken = _token(projectId);
    final certificateToken = _token(certificateId);
    final relativePath =
        'outputs/certificates/$certificateToken/certificate.$normalizedExtension';
    final path = await saveProjectWorkspaceFile(
      projectId: projectId,
      relativePath: relativePath,
      bytes: bytes,
    );
    if (path == null) {
      return _legacyStore.save(
        projectId: projectId,
        certificateId: certificateId,
        extension: normalizedExtension,
        bytes: bytes,
      );
    }
    return 'artifact://workspace/$projectToken/$certificateToken.$normalizedExtension';
  }

  @override
  Future<Uint8List?> read(String reference) async {
    final parsed = _parseWorkspaceReference(reference);
    if (parsed == null) return _legacyStore.read(reference);
    final bytes = await readProjectWorkspaceFile(
      projectId: parsed.projectId,
      relativePath:
          'outputs/certificates/${_token(parsed.certificateId)}/certificate.${parsed.extension}',
    );
    return bytes == null
        ? _legacyStore.read(reference)
        : Uint8List.fromList(bytes);
  }

  @override
  Future<void> delete(String reference) async {
    final parsed = _parseWorkspaceReference(reference);
    if (parsed == null) {
      await _legacyStore.delete(reference);
      return;
    }
    await deleteProjectWorkspaceFile(
      projectId: parsed.projectId,
      relativePath:
          'outputs/certificates/${_token(parsed.certificateId)}/certificate.${parsed.extension}',
    );
    await _legacyStore.delete(reference);
  }
}

class InMemoryCertificateArtifactStore implements CertificateArtifactStore {
  final Map<String, Uint8List> artifacts = {};

  @override
  Future<String> save({
    required String projectId,
    required String certificateId,
    required String extension,
    required List<int> bytes,
  }) async {
    final reference =
        'artifact://workspace/${_token(projectId)}/${_token(certificateId)}.${extension.toLowerCase()}';
    artifacts[reference] = Uint8List.fromList(bytes);
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async => artifacts[reference];

  @override
  Future<void> delete(String reference) async => artifacts.remove(reference);
}

String _token(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');

_WorkspaceArtifactReference? _parseWorkspaceReference(String reference) {
  final uri = Uri.tryParse(reference);
  if (uri == null || uri.scheme != 'artifact' || uri.host != 'workspace') {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length != 2) return null;
  final file = RegExp(
    r'^([A-Za-z0-9_-]+)\.([a-z0-9]{1,8})$',
  ).firstMatch(segments[1]);
  if (file == null) return null;
  try {
    return _WorkspaceArtifactReference(
      projectId: _decodeToken(segments[0]),
      certificateId: _decodeToken(file.group(1)!),
      extension: file.group(2)!,
    );
  } on FormatException {
    return null;
  }
}

String _decodeToken(String value) =>
    utf8.decode(base64Url.decode(base64Url.normalize(value)));

class _WorkspaceArtifactReference {
  const _WorkspaceArtifactReference({
    required this.projectId,
    required this.certificateId,
    required this.extension,
  });

  final String projectId;
  final String certificateId;
  final String extension;
}
