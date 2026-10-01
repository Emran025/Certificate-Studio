part of '../project_details_screen.dart';

class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({
    super.key,
    required this.project,
    required this.database,
    this.keyStorage,
    this.onClose,
  });

  final Project project;
  final AppDatabase database;
  final KeyStorage? keyStorage;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final transfer = WorkspaceTransferService(database);
    return Scaffold(
      body: AppPageTable(
        header: AppPageHeader(
          title: project.name,
          subtitle: project.description?.isNotEmpty == true
              ? project.description
              : context.l10n.text(
                  'Configure this project, then design and generate certificates.',
                ),
          icon: Icons.workspace_premium_outlined,
          actions: [
            IconButton(
              tooltip: context.l10n.text('Back to workspace'),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: context.l10n.text('Projectworkspace'),
                    action: AppStatusBadge(
                      label: (project.settings['project_type'] ?? 'course')
                          .toString()
                          .toUpperCase(),
                      color: context.themePrimary,
                      backgroundColor: context.themeSelection,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final action in [
                        _ProjectActionData(
                          icon: Icons.ios_share,
                          title: context.l10n.text('Export project'),
                          description: context.l10n.text(
                            'Export the background, font, data, and field positions.',
                          ),
                          onPressed: () async {
                            try {
                              final path = await transfer.exportProject(
                                project.id,
                              );
                              if (context.mounted && path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Project exported successfully.',
                                    ),
                                  ),
                                );
                              }
                            } on Object catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.text(
                                        'Export failed: $error',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _ProjectActionData(
                          icon: Icons.image_outlined,
                          title: context.l10n.text('Template'),
                          description: context.l10n.text(
                            'Choose the certificate background.',
                          ),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => TemplatePickerScreen(
                                database: database,
                                projectId: project.id,
                              ),
                            ),
                          ),
                        ),
                        _ProjectActionData(
                          icon: Icons.table_chart_outlined,
                          title: context.l10n.text('Record data'),
                          description: context.l10n.text(
                            'Import or paste recipient data.',
                          ),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => DataImportScreen(
                                database: database,
                                projectId: project.id,
                              ),
                            ),
                          ),
                        ),
                        _ProjectActionData(
                          icon: Icons.text_fields_outlined,
                          title: context.l10n.text('Fonts'),
                          description: context.l10n.text(
                            'Choose the font available to this project.',
                          ),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => FontsLibraryScreen(
                                database: database,
                                projectId: project.id,
                              ),
                            ),
                          ),
                        ),
                        _ProjectActionData(
                          icon: Icons.design_services_outlined,
                          title: context.l10n.text('Design'),
                          description: context.l10n.text(
                            'Place fields on the certificate canvas.',
                          ),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CertificateDesignerScreen(
                                database: database,
                                projectId: project.id,
                                projectName: project.name,
                              ),
                            ),
                          ),
                        ),
                        _ProjectActionData(
                          icon: Icons.play_circle_outline,
                          title: context.l10n.text('Generate'),
                          description: context.l10n.text(
                            'Create certificates after setup is complete.',
                          ),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CertificateGenerationScreen(
                                database: database,
                                keyStorage: keyStorage ?? InMemoryKeyStorage(),
                                projectId: project.id,
                                projectName: project.name,
                                institutionId: project.institutionId,
                              ),
                            ),
                          ),
                        ),
                      ])
                        _ProjectAction(data: action),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: context.themeSelection,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: context.themePrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                context.l10n.text('Project information'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = constraints.maxWidth < 520
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - AppSpacing.md) / 2;
                              return Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: [
                                  _InfoTile(
                                    width: itemWidth,
                                    icon: Icons.school_outlined,
                                    label: context.l10n.text('Course'),
                                    value:
                                        project.courseName ??
                                        context.l10n.text('Not set'),
                                  ),
                                  _InfoTile(
                                    width: itemWidth,
                                    icon: Icons.business_outlined,
                                    label: context.l10n.text('Organization'),
                                    value:
                                        project.organizationName ??
                                        context.l10n.text('Not set'),
                                  ),
                                  _InfoTile(
                                    width: itemWidth,
                                    icon: Icons.category_outlined,
                                    label: context.l10n.text('Type'),
                                    value:
                                        (project.settings['project_type'] ??
                                                'course')
                                            .toString(),
                                  ),
                                  _InfoTile(
                                    width: itemWidth,
                                    icon: Icons.calendar_today_outlined,
                                    label: context.l10n.text('Created'),
                                    value: _formatDate(project.createdAt),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
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

  // ignore: unused_element
  void _showComingNext(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available from this project workspace.',
        ),
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}
