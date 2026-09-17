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
    final values = data;
    const preferred = [
      'name',
      'full_name',
      'student_name',
      'recipient',
      'اسم',
      'الاسم',
      'اسم الطالب',
      'اسم المتدرب',
    ];
    for (final key in preferred) {
      final value = valueFor(key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    for (final entry in values.entries) {
      final value = entry.value?.toString().trim() ?? '';
      if (value.isNotEmpty && !_isTechnicalOrNumeric(entry.key, value)) {
        return value;
      }
    }
    final className = student?['class_name']?.toString().trim() ?? '';
    return className;
  }

  String get secondaryLabel {
    final entries = data.entries.where((entry) {
      final value = entry.value?.toString().trim() ?? '';
      return value.isNotEmpty && entry.value.toString() != recipient;
    });
    final entry = entries.firstWhere(
      (entry) => !_isTechnicalOrNumeric(
        entry.key,
        entry.value?.toString() ?? '',
      ),
      orElse: () => const MapEntry('', ''),
    );
    if (entry.key.isEmpty) return student?['class_name']?.toString() ?? '';
    return '${entry.key}: ${entry.value}';
  }

  String get searchText => [
    id,
    status,
    row['project_id'],
    row['student_id'],
    recipient,
    ...data.entries.expand((entry) => [entry.key, entry.value]),
  ].join(' ').toLowerCase();

  bool _isTechnicalOrNumeric(String key, String value) {
    final normalized = key.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '_',
    );
    return normalized == 'id' ||
        normalized.endsWith('_id') ||
        normalized == 'row_number' ||
        normalized == 'number' ||
        normalized == 'no' ||
        normalized == 'الرقم' ||
        RegExp(r'^\d+$').hasMatch(value);
  }
}
