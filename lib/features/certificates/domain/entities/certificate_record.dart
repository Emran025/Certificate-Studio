import 'dart:convert';

class CertificateRecord {
  CertificateRecord(this.row, this.student);
  final Map<String, Object?> row;
  final Map<String, Object?>? student;
  String get id => row['id']?.toString() ?? '';
  String get status => row['status']?.toString() ?? 'unknown';
  String? get imageReference => row['image_path'] as String?;
  String? get pdfReference => row['file_path'] as String?;
  Map<String, dynamic> get data {
    final rawStudent = student?['data_json'];
    if (rawStudent is String) {
      final decoded = jsonDecode(rawStudent);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    final rawDocument = row['document_json'];
    if (rawDocument is String) {
      final decoded = jsonDecode(rawDocument);
      final fields = decoded is Map ? decoded['fields'] : null;
      if (fields is Map) return Map<String, dynamic>.from(fields);
    }
    return {};
  }

  String? valueFor(String field) {
    final exact = data[field];
    if (exact != null) return exact.toString();
    final normalized = field.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
    for (final entry in data.entries) {
      if (entry.key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') ==
              normalized &&
          entry.value != null) {
        return entry.value.toString();
      }
    }
    return null;
  }

  String get recipient {
    final raw = student?['data_json'];
    if (raw is! String) return '';
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return '';
    for (final value in decoded.values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String get searchText =>
      '$id $status ${row['project_id']} $recipient'.toLowerCase();
}
