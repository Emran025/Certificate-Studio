part of '../app_shell.dart';

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
      _projectRepository = ProjectRepositoryImpl(ProjectDataSourceImpl(database));
      _createProject = CreateProject(
        _projectRepository!,
        ProjectKeyManager(widget.keyStorage ?? InMemoryKeyStorage()),
      );
      _projectsFuture = _loadProjects();
      _workspaceMetricsBloc = WorkspaceMetricsBloc(
        GetWorkspaceMetrics(WorkspaceRepositoryImpl(WorkspaceDataSourceImpl(database))),
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
