import 'dart:convert';
import 'dart:io';

Future<List<int>?> readTemplateBytes(String path) async {
  if (path.startsWith('data:')) return _decodeDataUri(path);
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

List<int>? _decodeDataUri(String value) {
  final comma = value.indexOf(',');
  if (comma < 0 || !value.substring(0, comma).endsWith(';base64')) return null;
  try {
    return base64Decode(value.substring(comma + 1));
  } on FormatException {
    return null;
  }
}
