class CertificateRecord {
  const CertificateRecord({
    required this.id,
    required this.status,
    this.projectId,
    this.recordId,
    this.className,
    this.imageReference,
    this.pdfReference,
    required this.data,
  });

  final String id;
  final String status;
  final String? projectId;
  final String? recordId;
  final String? className;
  final String? imageReference;
  final String? pdfReference;
  final Map<String, dynamic> data;

  String? valueFor(String field) {
    final exact = data[field];
    if (exact != null) return exact.toString();
    final normalized = field.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    for (final entry in data.entries) {
      if (entry.key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') == normalized &&
          entry.value != null) {
        return entry.value.toString();
      }
    }
    return null;
  }

  String get recipient {
    const preferred = [
      'name', 'full_name', 'record_name', 'recipient',
      'اسم', 'الاسم', 'اسم الطالب', 'اسم المتدرب',
    ];
    for (final key in preferred) {
      final value = valueFor(key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    for (final entry in data.entries) {
      final value = entry.value?.toString().trim() ?? '';
      if (value.isNotEmpty && !_isTechnicalOrNumeric(entry.key, value)) return value;
    }
    return className?.trim() ?? '';
  }

  String get secondaryLabel {
    final entries = data.entries.where((entry) {
      final value = entry.value?.toString().trim() ?? '';
      return value.isNotEmpty && entry.value.toString() != recipient;
    });
    final entry = entries.firstWhere(
      (entry) => !_isTechnicalOrNumeric(entry.key, entry.value?.toString() ?? ''),
      orElse: () => const MapEntry('', ''),
    );
    return entry.key.isEmpty ? className ?? '' : '${entry.key}: ${entry.value}';
  }

  String get searchText => [
        id,
        status,
        projectId,
        recordId,
        className,
        recipient,
        ...data.entries.expand((entry) => [entry.key, entry.value]),
      ].join(' ').toLowerCase();

  bool _isTechnicalOrNumeric(String key, String value) {
    final normalized = key.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '_');
    return normalized == 'id' || normalized.endsWith('_id') ||
        normalized == 'row_number' || normalized == 'number' ||
        normalized == 'no' || normalized == 'الرقم' || RegExp(r'^\d+$').hasMatch(value);
  }
}
