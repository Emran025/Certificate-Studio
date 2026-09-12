import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../data_import/presentation/screens/data_import_screen.dart';
import '../../../certificate_designer/presentation/screens/certificate_designer_screen.dart';
import '../../../certificate_generation/presentation/screens/certificate_generation_screen.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/entities/project.dart';

class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key, required this.project, required this.database, this.keyStorage});

  final Project project;
  final AppDatabase database;
  final KeyStorage? keyStorage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: 'Back to workspace',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  project.description?.isNotEmpty == true
                      ? project.description!
                      : 'Configure this project, then design and generate certificates.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _ProjectAction(
                      icon: Icons.image_outlined,
                      title: 'Template',
                      description: 'Choose the certificate background.',
                      onPressed: () => _showComingNext(context, 'Template selection'),
                    ),
                    _ProjectAction(
                      icon: Icons.table_chart_outlined,
                      title: 'Student data',
                      description: 'Import or paste recipient data.',
                      onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => DataImportScreen(database: database, projectId: project.id))),
                    ),
                    _ProjectAction(
                      icon: Icons.design_services_outlined,
                      title: 'Design',
                      description: 'Place fields on the certificate canvas.',
                      onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CertificateDesignerScreen(database: database, projectId: project.id, projectName: project.name))),
                    ),
                    _ProjectAction(
                      icon: Icons.play_circle_outline,
                      title: 'Generate',
                      description: 'Create certificates after setup is complete.',
                      onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CertificateGenerationScreen(database: database, keyStorage: keyStorage ?? InMemoryKeyStorage(), projectId: project.id, projectName: project.name, institutionId: project.institutionId))),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project information', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(label: 'Course', value: project.courseName ?? 'Not set'),
                      _InfoRow(label: 'Organization', value: project.organizationName ?? 'Not set'),
                      _InfoRow(label: 'Type', value: (project.settings['project_type'] ?? 'course').toString()),
                      _InfoRow(label: 'Created', value: _formatDate(project.createdAt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingNext(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available from this project workspace.')),
    );
  }

  String _formatDate(DateTime value) => '${value.day}/${value.month}/${value.year}';
}

class _ProjectAction extends StatelessWidget {
  const _ProjectAction({required this.icon, required this.title, required this.description, required this.onPressed});
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 410,
    child: AppSurfaceCard(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: AppSpacing.xxs), Text(description)])),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(children: [SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.labelLarge)), Expanded(child: Text(value))]),
  );
}
