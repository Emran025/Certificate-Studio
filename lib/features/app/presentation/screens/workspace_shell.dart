import 'package:flutter/material.dart';

import '../../../../config/env/app_environment.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../core/security/keys/project_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../institution/domain/entities/institution.dart';
import '../../../projects/data/repositories/project_repository_impl.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/usecases/create_project.dart';
import '../../../projects/presentation/screens/create_project_screen.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({super.key, this.database, this.institution});

  final AppDatabase? database;
  final Institution? institution;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  late final ProjectRepositoryImpl _projectRepository;
  late final CreateProject _createProject;
  Future<List<Project>>? _projectsFuture;

  @override
  void initState() {
    super.initState();
    final database = widget.database;
    if (database != null) {
      _projectRepository = ProjectRepositoryImpl(database);
      _createProject = CreateProject(_projectRepository, ProjectKeyManager(InMemoryKeyStorage()));
      _projectsFuture = _loadProjects();
    }
  }

  Future<List<Project>> _loadProjects() => _projectRepository.getAll(institutionId: widget.institution?.id);

  Future<void> _openCreateProject() async {
    final institution = widget.institution;
    if (institution == null || widget.database == null) return;
    final project = await Navigator.of(context).push<Project>(MaterialPageRoute(builder: (_) => CreateProjectScreen(institutionId: institution.id, createProject: _createProject)));
    if (project != null && mounted) setState(() => _projectsFuture = _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(children: [const _WorkspaceNavigation(), Expanded(child: _WorkspaceContent(database: widget.database, institution: widget.institution, projectsFuture: _projectsFuture, onCreateProject: _openCreateProject))]),
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation();

  @override
  Widget build(BuildContext context) => Container(width: 248, decoration: const BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.border))), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_outlined, color: Colors.white, size: 21)), const SizedBox(width: AppSpacing.sm), Text(AppEnvironment.appName, style: Theme.of(context).textTheme.titleMedium)]), const SizedBox(height: AppSpacing.xxl), const _NavigationItem(icon: Icons.home_outlined, label: 'Home', selected: true), const _NavigationItem(icon: Icons.folder_outlined, label: 'Projects'), const _NavigationItem(icon: Icons.image_outlined, label: 'Templates'), const _NavigationItem(icon: Icons.text_fields_outlined, label: 'Fonts'), const _NavigationItem(icon: Icons.workspace_premium_outlined, label: 'Certificates'), const Spacer(), const _NavigationItem(icon: Icons.verified_user_outlined, label: 'Verification'), const _NavigationItem(icon: Icons.settings_outlined, label: 'Settings')]);
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.icon, required this.label, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Semantics(button: true, label: label, child: Container(height: 44, decoration: BoxDecoration(color: selected ? AppColors.primaryLight : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.input)), child: ListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), leading: Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary), title: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? AppColors.primary : AppColors.textSecondary)), onTap: () {}))));
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({this.database, this.institution, this.projectsFuture, required this.onCreateProject});
  final AppDatabase? database;
  final Institution? institution;
  final Future<List<Project>>? projectsFuture;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) => Container(decoration: const BoxDecoration(gradient: AppGradients.page), child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xxl), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(institution?.name ?? 'Workspace', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)), const SizedBox(height: AppSpacing.xs), Text('Create and manage your certificates', style: Theme.of(context).textTheme.headlineLarge)])), if (database?.isOpen ?? false) ...[const AppStatusBadge(label: 'Offline ready'), const SizedBox(width: AppSpacing.md)], IconButton(tooltip: 'Notifications', onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined)), const SizedBox(width: AppSpacing.xs), IconButton(tooltip: 'Settings', onPressed: () {}, icon: const Icon(Icons.settings_outlined))]), const SizedBox(height: AppSpacing.xxl), Row(children: [Expanded(child: AppPrimaryButton(label: 'New project', icon: Icons.add, onPressed: onCreateProject)), const SizedBox(width: AppSpacing.md), Expanded(child: AppSecondaryButton(label: 'Import project', icon: Icons.file_upload_outlined, onPressed: () {}))]), const SizedBox(height: AppSpacing.xxl), const AppSectionHeader(title: 'Recent projects'), const SizedBox(height: AppSpacing.md), _ProjectsSection(projectsFuture: projectsFuture, onCreateProject: onCreateProject), const SizedBox(height: AppSpacing.xxl), const AppSectionHeader(title: 'Your workspace'), const SizedBox(height: AppSpacing.md), const Row(children: [Expanded(child: _MetricCard(icon: Icons.image_outlined, value: '0', label: 'Templates')), SizedBox(width: AppSpacing.md), Expanded(child: _MetricCard(icon: Icons.text_fields_outlined, value: '0', label: 'Fonts')), SizedBox(width: AppSpacing.md), Expanded(child: _MetricCard(icon: Icons.workspace_premium_outlined, value: '0', label: 'Certificates'))])]))));
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.projectsFuture, required this.onCreateProject});
  final Future<List<Project>>? projectsFuture;
  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    if (projectsFuture == null) return _EmptyProjects(onCreateProject: onCreateProject);
    return FutureBuilder<List<Project>>(future: projectsFuture, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator()));
      if (snapshot.hasError) return Text('Failed to load projects. Please try again.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error));
      final projects = snapshot.data ?? const <Project>[];
      if (projects.isEmpty) return _EmptyProjects(onCreateProject: onCreateProject);
      return Column(children: [for (final project in projects) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _ProjectPreviewCard(project: project))]);
    });
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreateProject});
  final VoidCallback onCreateProject;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.card)), child: const Icon(Icons.folder_open_outlined, color: AppColors.primary)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Create your first project'), SizedBox(height: AppSpacing.xxs), Text('Start with project information, then add a template and student data.')])) , AppSecondaryButton(label: 'Create project', onPressed: onCreateProject)]));
}

class _ProjectPreviewCard extends StatelessWidget {
  const _ProjectPreviewCard({required this.project});
  final Project project;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(padding: const EdgeInsets.all(AppSpacing.md), child: ListTile(contentPadding: EdgeInsets.zero, leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.input)), child: const Icon(Icons.description_outlined, color: AppColors.primary)), title: Text(project.name, style: Theme.of(context).textTheme.titleMedium), subtitle: Text('${project.courseName ?? 'Certificate project'}  •  Updated ${_relativeTime(project.updatedAt)}'), trailing: const AppStatusBadge(label: 'Draft'), onTap: () {}));

  String _relativeTime(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineMedium), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))])]));
}
