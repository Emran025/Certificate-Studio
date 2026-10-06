import 'dart:convert';

String recordsToCsv(List<Map<String, Object?>> records) {
  final maps = <Map<String, String>>[];
  final columns = <String>[];
  for (final record in records) {
    final raw = record['data_json'];
    if (raw is! String) continue;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) continue;
    final values = decoded.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
    maps.add(values);
    for (final key in values.keys) {
      if (!columns.contains(key)) columns.add(key);
    }
  }
  return [
    columns.map(csvCell).join(','),
    for (final row in maps)
      columns.map((column) => csvCell(row[column] ?? '')).join(','),
  ].join('\r\n');
}

List<Map<String, String>> csvToRows(String input) {
  final lines = input
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  if (lines.isEmpty || lines.first.trim().isEmpty) return [];
  final headers = parseCsvLine(lines.first);
  return [
    for (final line in lines.skip(1))
      if (line.trim().isNotEmpty)
        {
          for (var index = 0; index < headers.length; index++)
            headers[index]: index < parseCsvLine(line).length
                ? parseCsvLine(line)[index]
                : '',
        },
  ];
}

String csvCell(String value) => value.contains(RegExp('[,"]|\\r|\\n'))
    ? '"${value.replaceAll('"', '""')}"'
    : value;

List<String> parseCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '"') {
      if (quoted && index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(character);
    }
  }
  result.add(buffer.toString());
  return result;
}
