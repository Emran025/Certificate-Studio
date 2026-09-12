import 'dart:convert';

import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.institutionId,
    required super.name,
    super.courseName,
    super.description,
    super.startDate,
    super.endDate,
    super.trainerName,
    super.organizationName,
    super.logoPath,
    super.templateId,
    super.settings,
    required super.projectKeyReference,
    super.version,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProjectModel.fromRow(Map<String, Object?> row) {
    return ProjectModel(
      id: row['id']! as String,
      institutionId: row['institution_id']! as String,
      name: row['name']! as String,
      courseName: row['course_name'] as String?,
      description: row['description'] as String?,
      startDate: _parseDate(row['start_date'] as String?),
      endDate: _parseDate(row['end_date'] as String?),
      trainerName: row['trainer_name'] as String?,
      organizationName: row['organization_name'] as String?,
      logoPath: row['logo_path'] as String?,
      templateId: row['template_id'] as String?,
      settings: _decodeMap(row['settings_json'] as String?),
      projectKeyReference: row['project_key_reference']! as String,
      version: row['version']! as int,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'institution_id': institutionId,
        'name': name,
        'course_name': courseName,
        'description': description,
        'start_date': startDate?.toUtc().toIso8601String(),
        'end_date': endDate?.toUtc().toIso8601String(),
        'trainer_name': trainerName,
        'organization_name': organizationName,
        'logo_path': logoPath,
        'template_id': templateId,
        'settings_json': jsonEncode(settings),
        'project_key_reference': projectKeyReference,
        'version': version,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  static DateTime? _parseDate(String? value) => value == null ? null : DateTime.parse(value);

  static Map<String, Object?> _decodeMap(String? value) {
    if (value == null || value.isEmpty) return const {};
    return Map<String, Object?>.from(jsonDecode(value) as Map);
  }
}
