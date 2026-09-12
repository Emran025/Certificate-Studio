import 'dart:convert';

import '../../domain/entities/institution.dart';

class InstitutionModel extends Institution {
  const InstitutionModel({
    required super.id,
    required super.institutionId,
    required super.name,
    super.nameAr,
    super.nameEn,
    super.logoPath,
    super.contact,
    super.settings,
    required super.createdAt,
    required super.updatedAt,
  });

  factory InstitutionModel.fromRow(Map<String, Object?> row) {
    return InstitutionModel(
      id: row['id']! as String,
      institutionId: row['institution_id']! as String,
      name: row['name']! as String,
      nameAr: row['name_ar'] as String?,
      nameEn: row['name_en'] as String?,
      logoPath: row['logo_path'] as String?,
      contact: _decodeMap(row['contact_json'] as String?),
      settings: _decodeMap(row['settings_json'] as String?),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'institution_id': institutionId,
        'name': name,
        'name_ar': nameAr,
        'name_en': nameEn,
        'logo_path': logoPath,
        'contact_json': jsonEncode(contact),
        'settings_json': jsonEncode(settings),
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _decodeMap(String? value) {
    if (value == null || value.isEmpty) return const {};
    return Map<String, Object?>.from(jsonDecode(value) as Map);
  }
}
