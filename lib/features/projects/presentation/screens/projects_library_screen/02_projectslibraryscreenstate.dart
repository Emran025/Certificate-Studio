part of '../projects_library_screen.dart';

class _ProjectsLibraryScreenState extends State<ProjectsLibraryScreen> {
  late final ProjectRepositoryImpl _repository;
  late final CreateProject _createProject;
  late final ProjectsLibraryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _repository = ProjectRepositoryImpl(widget.database);
    _createProject = CreateProject(
      _repository,
      ProjectKeyManager(widget.keyStorage),
    );
    _bloc = ProjectsLibraryBloc(
      _repository,
      DeleteProject(_repository, widget.keyStorage),
      widget.institutionId,
    )..add(const ProjectsRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _create() async {
    final project = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          institutionId: widget.institutionId,
          createProject: _createProject,
        ),
      ),
    );
    if (project != null && mounted) _bloc.add(const ProjectsRequested());
  }

  Future<void> _importProject() async {
    try {
      final id = await WorkspaceTransferService(
        widget.database,
      ).importProject(widget.institutionId);
      if (!mounted || id == null) return;
      _bloc.add(const ProjectsRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.text('Project imported successfully.'),
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.text('Import failed: $error'))),
      );
    }
  }

  Future<void> _open(Project project) async {
    final onOpenProject = widget.onOpenProject;
    if (onOpenProject != null) {
      onOpenProject(project);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(
          project: project,
          database: widget.database,
          keyStorage: widget.keyStorage,
        ),
      ),
    );
  }

  Future<void> _generate(Project project) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CertificateGenerationScreen(
          database: widget.database,
          keyStorage: widget.keyStorage,
          projectId: project.id,
          projectName: project.name,
          institutionId: project.institutionId,
        ),
      ),
    );
  }

  Future<void> _delete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: Text(context.l10n.text('Delete ${project.name}?')),
        icon: Icons.delete_outline,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.text('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.text('Delete project')),
          ),
        ],
        child: Text(
          context.l10n.text(
            'This permanently removes the project, recipient data, design, generated certificates, verification records, and project key.',
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    if (mounted) _bloc.add(ProjectDeleted(project));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocListener<ProjectsLibraryBloc, ProjectsLibraryState>(
      listener: (context, state) {
        if (state.deletedProjectName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.text('${state.deletedProjectName} deleted'),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<ProjectsLibraryBloc, ProjectsLibraryState>(
          builder: (context, state) {
            if (state.status == ProjectsLibraryStatus.loading ||
                state.status == ProjectsLibraryStatus.deleting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ProjectsLibraryStatus.failure) {
              return Center(
                child: Text(
                  context.l10n.text(
                    'Unable to load projects: ${state.errorMessage}',
                  ),
                ),
              );
            }
            final projects = state.projects;
            return AppPageTable(
              header: AppPageHeader(
                title: context.l10n.text('Project workspace'),
                subtitle: context.l10n.text(
                  'Manage projects and import existing workspaces.',
                ),
                icon: Icons.folder_outlined,
                actions: [
                  OutlinedButton.icon(
                    onPressed: _importProject,
                    icon: const Icon(Icons.file_open_outlined),
                    label: Text(context.l10n.text('Import project')),
                  ),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.text('New project')),
                  ),
                ],
              ),
              child: projects.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.text(
                                'No projects have been created yet.',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: _create,
                              icon: const Icon(Icons.add),
                              label: Text(context.l10n.text('Create project')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: projects.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.themeBorder),
                      itemBuilder: (_, index) => _ProjectTile(
                        project: projects[index],
                        onTap: () => _open(projects[index]),
                        onGenerate: () => _generate(projects[index]),
                        onDelete: () => _delete(projects[index]),
                      ),
                    ),
            );
          },
        ),
      ),
    ),
  );
}
