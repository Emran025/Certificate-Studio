import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../verification/presentation/screens/verification_screen.dart';
import '../../../certificates/presentation/screens/certificate_library_screen.dart';
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
import '../../../projects/presentation/screens/project_details_screen.dart';
import '../../../projects/presentation/screens/projects_library_screen.dart';
import '../../../templates/presentation/screens/template_picker_screen.dart';
import '../../../fonts/presentation/screens/fonts_library_screen.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    this.database,
    this.institution,
    this.keyStorage,
  });

  final AppDatabase? database;
  final Institution? institution;
  final KeyStorage? keyStorage;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  ProjectRepositoryImpl? _projectRepository;
  CreateProject? _createProject;
  Future<List<Project>>? _projectsFuture;
  Project? _activeProject;
  bool _showProjects = false;
  String _selectedNavigation = 'home';

  @override
  void initState() {
    super.initState();
    final database = widget.database;
    if (database != null) {
      _projectRepository = ProjectRepositoryImpl(database);
      _createProject = CreateProject(
        _projectRepository!,
        ProjectKeyManager(widget.keyStorage ?? InMemoryKeyStorage()),
      );
      _projectsFuture = _loadProjects();
    }
  }

  Future<List<Project>> _loadProjects() {
    final repo = _projectRepository;
    if (repo == null) return Future.value(const <Project>[]);
    return repo.getAll(institutionId: widget.institution?.id);
  }

  Future<void> _openCreateProject() async {
    final institution = widget.institution;
    final createProject = _createProject;
    if (institution == null || createProject == null) return;

    final project = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          institutionId: institution.id,
          createProject: createProject,
        ),
      ),
    );
    if (project != null && mounted) {
      final future = _loadProjects();
      setState(() {
        _projectsFuture = future;
      });
    }
  }

  Future<void> _openProject(Project project) async {
    if (!mounted) return;
    setState(() {
      _activeProject = project;
      _showProjects = false;
      _selectedNavigation = 'projects';
    });
  }

  void _openCertificateLibrary() {
    if (!mounted || widget.database == null) return;
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'certificates';
    });
  }

  void _openProjects() {
    if (!mounted || widget.database == null || widget.institution == null)
      return;
    setState(() {
      _activeProject = null;
      _showProjects = true;
      _selectedNavigation = 'projects';
    });
  }

  void _showHome() {
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'home';
    });
  }

  void _openTemplates() {
    if (!mounted || widget.database == null) return;
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'templates';
    });
  }

  void _openFonts() {
    if (!mounted || widget.database == null) return;
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'fonts';
    });
  }

  void _openVerification() {
    if (!mounted || widget.database == null) return;
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'verification';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _WorkspaceNavigation(
              selected: _selectedNavigation,
              onHome: _showHome,
              onProjects: _openProjects,
              onTemplates: _openTemplates,
              onFonts: _openFonts,
              onCertificates: _openCertificateLibrary,
              onVerification: _openVerification,
            ),
            Expanded(
              child: _activeProject != null
                  ? ProjectDetailsScreen(
                      project: _activeProject!,
                      database: widget.database!,
                      keyStorage: widget.keyStorage,
                      onClose: _showHome,
                    )
                  : _showProjects
                  ? ProjectsLibraryScreen(
                      database: widget.database!,
                      institutionId: widget.institution!.id,
                      keyStorage: widget.keyStorage ?? InMemoryKeyStorage(),
                      onOpenProject: _openProject,
                      onClose: _showHome,
                    )
                  : _selectedNavigation == 'templates'
                  ? TemplatePickerScreen(database: widget.database!)
                  : _selectedNavigation == 'fonts'
                  ? FontsLibraryScreen(database: widget.database!)
                  : _selectedNavigation == 'certificates'
                  ? CertificateLibraryScreen(
                      database: widget.database!,
                      keyStorage: widget.keyStorage ?? InMemoryKeyStorage(),
                    )
                  : _selectedNavigation == 'verification'
                  ? VerificationScreen(
                      database: widget.database!,
                      keyStorage: widget.keyStorage ?? InMemoryKeyStorage(),
                    )
                  : _WorkspaceContent(
                      database: widget.database,
                      institution: widget.institution,
                      projectsFuture: _projectsFuture,
                      onCreateProject: _openCreateProject,
                      onVerify: _openVerification,
                      onOpenProject: _openProject,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.selected,
    this.onHome,
    this.onProjects,
    this.onTemplates,
    this.onFonts,
    this.onCertificates,
    this.onVerification,
  });

  final String selected;
  final VoidCallback? onHome;
  final VoidCallback? onProjects;
  final VoidCallback? onTemplates;
  final VoidCallback? onFonts;
  final VoidCallback? onCertificates;
  final VoidCallback? onVerification;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: 248,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/certificate_studio_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppEnvironment.appName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _NavigationItem(
              icon: Icons.home_outlined,
              label: context.l10n.text('home'),
              selected: selected == 'home',
              onTap: onHome,
            ),
            _NavigationItem(
              icon: Icons.folder_outlined,
              label: context.l10n.text('projects'),
              selected: selected == 'projects',
              onTap: onProjects,
            ),
            _NavigationItem(
              icon: Icons.image_outlined,
              label: context.l10n.text('templates'),
              selected: selected == 'templates',
              onTap: onTemplates,
            ),
            _NavigationItem(
              icon: Icons.text_fields_outlined,
              label: context.l10n.text('fonts'),
              selected: selected == 'fonts',
              onTap: onFonts,
            ),
            _NavigationItem(
              icon: Icons.workspace_premium_outlined,
              label: context.l10n.text('certificates'),
              selected: selected == 'certificates',
              onTap: onCertificates,
            ),
            const Spacer(),
            _NavigationItem(
              icon: Icons.verified_user_outlined,
              label: context.l10n.text('verification'),
              selected: selected == 'verification',
              onTap: onVerification,
            ),
            _NavigationItem(
              icon: Icons.settings_outlined,
              label: context.l10n.text('settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.input),
            onTap: onTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    this.database,
    this.institution,
    this.projectsFuture,
    required this.onCreateProject,
    required this.onVerify,
    required this.onOpenProject,
  });

  final AppDatabase? database;
  final Institution? institution;
  final Future<List<Project>>? projectsFuture;
  final VoidCallback onVerify;
  final VoidCallback onCreateProject;
  final ValueChanged<Project> onOpenProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.page),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          institution?.name ?? context.l10n.text('Workspace'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.text(
                            'Create and manage your certificates',
                          ),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  if (database?.isOpen ?? false) ...[
                    AppStatusBadge(label: 'Offline ready'),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  IconButton(
                    tooltip: context.l10n.text('Notifications'),
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_outlined),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: context.l10n.text('Settings'),
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: Text(context.l10n.text('Verify')),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'New project',
                      icon: Icons.add,
                      onPressed: onCreateProject,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Import project',
                      icon: Icons.file_upload_outlined,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSectionHeader(title: 'Recent projects'),
              const SizedBox(height: AppSpacing.md),
              _ProjectsSection(
                projectsFuture: projectsFuture,
                onCreateProject: onCreateProject,
                onOpenProject: onOpenProject,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSectionHeader(title: 'Your workspace'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.image_outlined,
                      value: '0',
                      label: context.l10n.text('templates'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.text_fields_outlined,
                      value: '0',
                      label: context.l10n.text('fonts'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.workspace_premium_outlined,
                      value: '0',
                      label: context.l10n.text('certificates'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.projectsFuture,
    required this.onCreateProject,
    required this.onOpenProject,
  });

  final Future<List<Project>>? projectsFuture;
  final VoidCallback onCreateProject;
  final ValueChanged<Project> onOpenProject;

  @override
  Widget build(BuildContext context) {
    if (projectsFuture == null) {
      return _EmptyProjects(onCreateProject: onCreateProject);
    }
    return FutureBuilder<List<Project>>(
      future: projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            context.l10n.text('Failed to load projects. Please try again.'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
          );
        }
        final projects = snapshot.data ?? const <Project>[];
        if (projects.isEmpty) {
          return _EmptyProjects(onCreateProject: onCreateProject);
        }
        return Column(
          children: [
            for (final project in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProjectPreviewCard(
                  project: project,
                  onTap: () => onOpenProject(project),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreateProject});

  final VoidCallback onCreateProject;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('Create your first project'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.l10n.text(
                    'Start with project information, then add a template and student data.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSecondaryButton(
            label: 'Create project',
            onPressed: onCreateProject,
          ),
        ],
      ),
    );
  }
}

class _ProjectPreviewCard extends StatelessWidget {
  const _ProjectPreviewCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            project.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            context.l10n.text('projectUpdated', {
              'course':
                  project.courseName ??
                  context.l10n.text('Certificate project'),
              'date': _relativeTime(project.updatedAt),
            }),
          ),
          trailing: AppStatusBadge(label: 'Draft'),
          onTap: onTap,
        ),
      ),
    );
  }

  String _relativeTime(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
