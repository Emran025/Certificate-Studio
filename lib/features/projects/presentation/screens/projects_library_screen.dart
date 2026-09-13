import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../core/security/keys/project_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/create_project.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';

class ProjectsLibraryScreen extends StatefulWidget {
  const ProjectsLibraryScreen({super.key, required this.database, required this.institutionId, required this.keyStorage, this.onOpenProject, this.onClose});
  final AppDatabase database;
  final String institutionId;
  final KeyStorage keyStorage;
  final ValueChanged<Project>? onOpenProject;
  final VoidCallback? onClose;
  @override
  State<ProjectsLibraryScreen> createState() => _ProjectsLibraryScreenState();
}

class _ProjectsLibraryScreenState extends State<ProjectsLibraryScreen> {
  late final ProjectRepositoryImpl _repository;
  late final CreateProject _createProject;
  late Future<List<Project>> _projects;

  @override
  void initState() {
    super.initState();
    _repository = ProjectRepositoryImpl(widget.database);
    _createProject = CreateProject(_repository, ProjectKeyManager(widget.keyStorage));
    _projects = _load();
  }

  Future<List<Project>> _load() => _repository.getAll(institutionId: widget.institutionId);

  Future<void> _create() async {
    final project = await Navigator.of(context).push<Project>(MaterialPageRoute(builder: (_) => CreateProjectScreen(institutionId: widget.institutionId, createProject: _createProject)));
    if (project != null && mounted) {
      final projects = _load();
      setState(() {
        _projects = projects;
      });
    }
  }

  Future<void> _open(Project project) async {
    final onOpenProject = widget.onOpenProject;
    if (onOpenProject != null) {
      onOpenProject(project);
      return;
    }
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: project, database: widget.database, keyStorage: widget.keyStorage)));
    if (mounted) {
      final projects = _load();
      setState(() {
        _projects = projects;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Projects'),
      leading: widget.onClose == null ? null : IconButton(onPressed: widget.onClose, icon: const Icon(Icons.arrow_back)),
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New project')),
    body: FutureBuilder<List<Project>>(
      future: _projects,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Unable to load projects: ${snapshot.error}'));
        final projects = snapshot.data ?? const <Project>[];
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Project workspace', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('${projects.length} persisted project${projects.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: projects.isEmpty ? AppSurfaceCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('No projects have been created yet.'), const SizedBox(height: AppSpacing.md), FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Create project'))])) : ListView.separated(itemCount: projects.length, separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm), itemBuilder: (_, index) => _ProjectTile(project: projects[index], onTap: () => _open(projects[index])))),
          ]))),
        );
      },
    ),
  );
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.onTap});
  final Project project;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(child: ListTile(contentPadding: EdgeInsets.zero, onTap: onTap, leading: const CircleAvatar(child: Icon(Icons.folder_outlined)), title: Text(project.name), subtitle: Text([if (project.courseName?.isNotEmpty == true) project.courseName!, if (project.organizationName?.isNotEmpty == true) project.organizationName!, 'Created ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}'].join(' · ')), trailing: const Icon(Icons.chevron_right)));
}
