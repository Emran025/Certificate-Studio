import 'dart:convert';

import '../../domain/entities/certificate_record.dart';

/// Database DTO for [CertificateRecord].
///
/// All row/JSON knowledge stays in the data layer; the domain entity receives
/// already-normalized values only.
class CertificateRecordModel extends CertificateRecord {
  const CertificateRecordModel({
    required super.id,
    required super.status,
    required super.projectId,
    required super.recordId,
    super.className,
    super.imageReference,
    super.pdfReference,
    super.documentHash,
    required super.data,
  });

  factory CertificateRecordModel.fromRows(
    Map<String, Object?> certificateRow,
    Map<String, Object?>? recordRow,
  ) {
    return CertificateRecordModel(
      id: certificateRow['id']?.toString() ?? '',
      status: certificateRow['status']?.toString() ?? 'unknown',
      projectId: certificateRow['project_id']?.toString(),
      recordId: certificateRow['record_id']?.toString(),
      className: recordRow?['class_name']?.toString(),
      imageReference: certificateRow['image_path'] as String?,
      pdfReference: certificateRow['file_path'] as String?,
      documentHash: certificateRow['document_hash'] as String?,
      data: _decodeData(recordRow, certificateRow),
    );
  }

  static Map<String, dynamic> _decodeData(
    Map<String, Object?>? recordRow,
    Map<String, Object?> certificateRow,
  ) {
    final recordData = _decodeMap(recordRow?['data_json']);
    if (recordData.isNotEmpty) return recordData;

    final document = _decodeMap(certificateRow['document_json']);
    final fields = document['fields'];
    return fields is Map ? Map<String, dynamic>.from(fields) : <String, dynamic>{};
  }

  static Map<String, dynamic> _decodeMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
  }
}
