import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../verification/presentation/screens/verification_screen.dart';
import '../../../certificates/presentation/screens/certificate_library_screen.dart';
import '../../../../config/env/app_environment.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../core/security/keys/project_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../domain/entities/workspace_metrics.dart';
import '../../domain/usecases/get_workspace_metrics.dart';
import '../../../institution/domain/entities/institution.dart';
import '../../../projects/data/repositories/project_repository_impl.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/usecases/create_project.dart';
import '../../../projects/presentation/screens/create_project_screen.dart';
import '../../../projects/presentation/screens/project_details_screen.dart';
import '../../../projects/presentation/screens/projects_library_screen.dart';
import '../../../templates/presentation/screens/template_picker_screen.dart';
import '../../../fonts/presentation/screens/fonts_library_screen.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../controllers/workspace_metrics_bloc.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    this.database,
    this.institution,
    this.keyStorage,
    this.appSettings = const AppSettings(),
    this.onSettingsChanged,
  });

  final AppDatabase? database;
  final Institution? institution;
  final KeyStorage? keyStorage;
  final AppSettings appSettings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  void _openSettings() {
    if (!mounted || widget.database == null || widget.institution == null) {
      return;
    }
    setState(() {
      _activeProject = null;
      _showProjects = false;
      _selectedNavigation = 'settings';
    });
  }

  ProjectRepositoryImpl? _projectRepository;
  CreateProject? _createProject;
  Future<List<Project>>? _projectsFuture;
  WorkspaceMetricsBloc? _workspaceMetricsBloc;
  Project? _activeProject;
  bool _showProjects = false;
  String _selectedNavigation = 'home';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
      _workspaceMetricsBloc = WorkspaceMetricsBloc(
        GetWorkspaceMetrics(WorkspaceRepositoryImpl(database)),
      )..add(const WorkspaceMetricsRequested());
    }
  }

  Future<List<Project>> _loadProjects() {
    final repo = _projectRepository;
    if (repo == null) return Future.value(const <Project>[]);
    return repo.getAll(institutionId: widget.institution?.id);
  }

  @override
  void dispose() {
    _workspaceMetricsBloc?.close();
    super.dispose();
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
    if (!mounted || widget.database == null || widget.institution == null) {
      return;
    }
    setState(() {
      _activeProject = null;
      _showProjects = true;
      _selectedNavigation = 'projects';
    });
  }

  void _showHome() {
    _workspaceMetricsBloc?.add(const WorkspaceMetricsRequested());
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

  Widget _buildWorkspaceContent() {
    final bloc = _workspaceMetricsBloc;
    if (bloc == null) {
      return _WorkspaceContent(
        database: widget.database,
        institution: widget.institution,
        projectsFuture: _projectsFuture,
        metrics: const WorkspaceMetrics.empty(),
        onCreateProject: _openCreateProject,
        onVerify: _openVerification,
        onOpenProject: _openProject,
      );
    }

    return BlocBuilder<WorkspaceMetricsBloc, WorkspaceMetricsState>(
      bloc: bloc,
      builder: (context, state) => _WorkspaceContent(
        database: widget.database,
        institution: widget.institution,
        projectsFuture: _projectsFuture,
        metrics: state.metrics,
        metricsError: state.errorMessage,
        onCreateProject: _openCreateProject,
        onVerify: _openVerification,
        onOpenProject: _openProject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < AppBreakpoints.desktop;
        final content = _activeProject != null
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
            : _selectedNavigation == 'settings'
            ? SettingsScreen(
                database: widget.database!,
                institutionId: widget.institution!.id,
                settings: widget.appSettings,
                keyStorage: widget.keyStorage ?? InMemoryKeyStorage(),
                onSettingsChanged: widget.onSettingsChanged,
              )
            : _buildWorkspaceContent();
        void navigate(VoidCallback? action) {
          action?.call();
          if (useDrawer) _scaffoldKey.currentState?.closeDrawer();
        }

        final navigation = _WorkspaceNavigation(
          selected: _selectedNavigation,
          onHome: () => navigate(_showHome),
          onProjects: () => navigate(_openProjects),
          onTemplates: () => navigate(_openTemplates),
          onFonts: () => navigate(_openFonts),
          onCertificates: () => navigate(_openCertificateLibrary),
          onVerification: () => navigate(_openVerification),
          onSettings: () => navigate(_openSettings),
        );

        return Scaffold(
          key: _scaffoldKey,
          drawer: useDrawer ? Drawer(child: SafeArea(child: navigation)) : null,
          body: SafeArea(
            child: Column(
              children: [
                if (useDrawer)
                  _CompactWorkspaceHeader(
                    onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      if (!useDrawer) navigation,
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactWorkspaceHeader extends StatelessWidget {
  const _CompactWorkspaceHeader({required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.themeBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onOpenDrawer,
              tooltip: context.l10n.text('Open navigation'),
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Image.asset(
                'assets/images/certificate_studio_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.text(AppEnvironment.appNameKey),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
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
    this.onSettings,
  });

  final String selected;
  final VoidCallback? onHome;
  final VoidCallback? onProjects;
  final VoidCallback? onTemplates;
  final VoidCallback? onFonts;
  final VoidCallback? onCertificates;
  final VoidCallback? onVerification;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        gradient: context.themeSidebarGradient,
        border: Border(right: BorderSide(color: context.themeBorder)),
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
                  context.l10n.text(AppEnvironment.appNameKey),
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
            selected: selected == 'settings',
            onTap: onSettings,
          ),
        ],
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
          color: selected ? context.themeSelection : Colors.transparent,
          child: InkWell(
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
                        ? context.themePrimary
                        : context.themeMutedText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? context.themePrimary
                            : context.themeMutedText,
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
    required this.metrics,
    this.metricsError,
    required this.onCreateProject,
    required this.onVerify,
    required this.onOpenProject,
  });

  final AppDatabase? database;
  final Institution? institution;
  final Future<List<Project>>? projectsFuture;
  final WorkspaceMetrics metrics;
  final String? metricsError;
  final VoidCallback onVerify;
  final VoidCallback onCreateProject;
  final ValueChanged<Project> onOpenProject;

  @override
  Widget build(BuildContext context) {
    return AppPageTable(
      header: AppPageHeader(
        title: context.l10n.text('Create and manage your certificates'),
        subtitle: institution?.name ?? context.l10n.text('Workspace'),
        icon: Icons.workspace_premium_outlined,
        actions: [
          if (database?.isOpen ?? false)
            AppStatusBadge(label: context.l10n.text('offlineReady')),
          IconButton(
            tooltip: context.l10n.text('Notifications'),
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          IconButton(
            tooltip: context.l10n.text('Settings'),
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
          OutlinedButton.icon(
            onPressed: onVerify,
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(context.l10n.text('Verify')),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttons = [
                      AppPrimaryButton(
                        label: context.l10n.text('newProject'),
                        icon: Icons.add,
                        onPressed: onCreateProject,
                      ),
                      AppSecondaryButton(
                        label: context.l10n.text('importProject'),
                        icon: Icons.file_upload_outlined,
                        onPressed: () {},
                      ),
                    ];
                    if (constraints.maxWidth < AppBreakpoints.mobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons[0],
                          const SizedBox(height: AppSpacing.sm),
                          buttons[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: buttons[0]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: buttons[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppSectionHeader(title: context.l10n.text('recentProjects')),
                const SizedBox(height: AppSpacing.md),
                _ProjectsSection(
                  projectsFuture: projectsFuture,
                  onCreateProject: onCreateProject,
                  onOpenProject: onOpenProject,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppSectionHeader(title: context.l10n.text('yourWorkspace')),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < AppBreakpoints.tablet;
                    final cards = [
                      _MetricCard(
                        icon: Icons.image_outlined,
                        value: metrics.templates.toString(),
                        label: context.l10n.text('templates'),
                      ),
                      _MetricCard(
                        icon: Icons.text_fields_outlined,
                        value: metrics.fonts.toString(),
                        label: context.l10n.text('fonts'),
                      ),
                      _MetricCard(
                        icon: Icons.workspace_premium_outlined,
                        value: metrics.certificates.toString(),
                        label: context.l10n.text('certificates'),
                      ),
                    ];
                    if (compact) {
                      return Column(
                        children: [
                          for (final card in cards) ...[
                            card,
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          if (index > 0) const SizedBox(width: AppSpacing.md),
                          Expanded(child: cards[index]),
                        ],
                      ],
                    );
                  },
                ),
                if (metricsError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.text('Failed to load workspace metrics.'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: context.themeError),
                  ),
                ],
              ],
            ),
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
            ).textTheme.bodyMedium?.copyWith(color: context.themeError),
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
              color: context.themeSelection,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              color: context.themePrimary,
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
                    color: context.themeMutedText,
                  ),
                ),
              ],
            ),
          ),
          AppSecondaryButton(
            label: context.l10n.text('createProject'),
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
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.themeSelection,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(
              Icons.description_outlined,
              color: context.themePrimary,
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
          trailing: AppStatusBadge(label: context.l10n.text('Draft')),
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
          Icon(icon, color: context.themePrimary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.themeMutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
