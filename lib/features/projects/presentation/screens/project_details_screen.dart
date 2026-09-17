import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../data_import/presentation/screens/data_import_screen.dart';
import '../../../certificates/presentation/screens/certificate_designer_screen.dart';
import '../../../certificates/presentation/screens/certificate_generation_screen.dart';
import '../../../templates/presentation/screens/template_picker_screen.dart';
import '../../../fonts/presentation/screens/fonts_library_screen.dart';
import '../../../settings/data/services/workspace_transfer_service.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/entities/project.dart';

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
                          title: context.l10n.text('Student data'),
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

class _ProjectAction extends StatelessWidget {
  const _ProjectAction({required this.data});
  final _ProjectActionData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth >= 600 ? 410 : constraints.maxWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor,
        child: InkWell(
          onTap: data.onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.themeSelection,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Icon(data.icon, color: context.themePrimary, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.text(data.title),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        context.l10n.text(data.description),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.themeMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: context.themeMutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProjectActionData {
  const _ProjectActionData({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: context.themePrimary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.themeMutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
