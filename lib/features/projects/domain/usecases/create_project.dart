import '../entities/project.dart';
import '../repositories/project_repository.dart';
import '../services/project_key_service.dart';

class CreateProjectParams {
  const CreateProjectParams({required this.name, required this.institutionId, this.organizationName, this.description, this.courseName, this.projectType = 'course'});

  final String name;
  final String institutionId;
  final String? organizationName;
  final String? description;
  final String? courseName;
  final String projectType;
}

class CreateProject {
  CreateProject(this._repository, this._keyManager);

  final ProjectRepository _repository;
  final ProjectKeyService _keyManager;

  Future<Project> call(CreateProjectParams params) async {
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) throw ArgumentError.value(params.name, 'name', 'Project name is required.');
    if (params.institutionId.trim().isEmpty) throw ArgumentError.value(params.institutionId, 'institutionId', 'Institution is required.');

    final now = DateTime.now().toUtc();
    final id = 'project-${now.microsecondsSinceEpoch}';
    await _keyManager.initialize(id);
    final project = Project(
      id: id,
      institutionId: params.institutionId,
      name: trimmedName,
      courseName: _optional(params.courseName),
      description: _optional(params.description),
      organizationName: _optional(params.organizationName),
      settings: {'project_type': params.projectType},
      projectKeyReference: 'project:$id',
      createdAt: now,
      updatedAt: now,
    );
    return _repository.save(project);
  }

  String? _optional(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}
