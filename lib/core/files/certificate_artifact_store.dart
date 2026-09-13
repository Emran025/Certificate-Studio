import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores generated certificate bytes behind stable, database-friendly references.
/// SharedPreferences is used as the portable fallback so generation also works on
/// web; a native filesystem implementation can replace this adapter later.
class CertificateArtifactStore {
  CertificateArtifactStore({this._preferences});

  SharedPreferences? _preferences;

  Future<String> save({required String certificateId, required String extension, required List<int> bytes}) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final reference = 'artifact://certificates/$certificateId.$extension';
    await preferences.setString(_key(reference), base64Encode(bytes));
    return reference;
  }

  Future<Uint8List?> read(String reference) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key(reference));
    return encoded == null ? null : Uint8List.fromList(base64Decode(encoded));
  }

  Future<void> delete(String reference) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.remove(_key(reference));
  }

  String _key(String reference) => 'certificate_artifact:$reference';
}

/// Deterministic test adapter; it also makes the generation service easy to use
/// in headless environments where platform preferences are unavailable.
class InMemoryCertificateArtifactStore extends CertificateArtifactStore {
  final Map<String, Uint8List> artifacts = {};

  @override
  Future<String> save({required String certificateId, required String extension, required List<int> bytes}) async {
    final reference = 'artifact://certificates/$certificateId.$extension';
    artifacts[reference] = Uint8List.fromList(bytes);
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async => artifacts[reference];
}
