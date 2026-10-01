import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CertificateArtifactStore {
  Future<String> save({required String certificateId, required String extension, required List<int> bytes});
  Future<Uint8List?> read(String reference);
  Future<void> delete(String reference);
}

class SharedPreferencesCertificateArtifactStore implements CertificateArtifactStore {
  SharedPreferencesCertificateArtifactStore({this._preferences});
  SharedPreferences? _preferences;

  @override
  Future<String> save({required String certificateId, required String extension, required List<int> bytes}) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final reference = 'artifact://certificates/$certificateId.$extension';
    await preferences.setString(_key(reference), base64Encode(bytes));
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key(reference));
    return encoded == null ? null : Uint8List.fromList(base64Decode(encoded));
  }

  @override
  Future<void> delete(String reference) async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.remove(_key(reference));
  }

  String _key(String reference) => 'certificate_artifact:$reference';
}

class InMemoryCertificateArtifactStore implements CertificateArtifactStore {
  final Map<String, Uint8List> artifacts = {};

  @override
  Future<String> save({required String certificateId, required String extension, required List<int> bytes}) async {
    final reference = 'artifact://certificates/$certificateId.$extension';
    artifacts[reference] = Uint8List.fromList(bytes);
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async => artifacts[reference];

  @override
  Future<void> delete(String reference) async => artifacts.remove(reference);
}
