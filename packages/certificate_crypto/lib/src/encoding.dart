import 'dart:convert';

String base64UrlEncodeNoPadding(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
List<int> base64UrlDecode(String value) => base64Url.decode(base64Url.normalize(value));

String canonicalJson(Object? value) {
  final buffer = StringBuffer();
  void writeValue(Object? value) {
    if (value == null || value is bool || value is num) {
      buffer.write(jsonEncode(value));
    } else if (value is String) {
      buffer.write(jsonEncode(value));
    } else if (value is List) {
      buffer.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) buffer.write(',');
        writeValue(value[i]);
      }
      buffer.write(']');
    } else if (value is Map) {
      final keys = value.keys.whereType<String>().toList()..sort();
      if (keys.length != value.length) throw ArgumentError('canonical maps require string keys');
      buffer.write('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write(jsonEncode(keys[i]));
        buffer.write(':');
        writeValue(value[keys[i]]);
      }
      buffer.write('}');
    } else {
      throw ArgumentError('unsupported canonical JSON value: ${value.runtimeType}');
    }
  }
  writeValue(value);
  return buffer.toString();
}
List<int> canonicalJsonBytes(Object? value) => utf8.encode(canonicalJson(value));
