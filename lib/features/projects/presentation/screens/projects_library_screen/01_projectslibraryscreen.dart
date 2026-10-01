part of '../projects_library_screen.dart';

class ProjectsLibraryScreen extends StatefulWidget {
  const ProjectsLibraryScreen({
    super.key,
    required this.database,
    required this.institutionId,
    required this.keyStorage,
    this.onOpenProject,
    this.onClose,
  });
  final AppDatabase database;
  final String institutionId;
  final KeyStorage keyStorage;
  final ValueChanged<Project>? onOpenProject;
  final VoidCallback? onClose;
  @override
  State<ProjectsLibraryScreen> createState() => _ProjectsLibraryScreenState();
}
