import 'dart:convert';

Future<List<int>?> readTemplateBytes(String path) async {
  if (!path.startsWith('data:')) return null;
  final comma = path.indexOf(',');
  if (comma < 0 || !path.substring(0, comma).endsWith(';base64')) return null;
  try {
    return base64Decode(path.substring(comma + 1));
  } on FormatException {
    return null;
  }
}
