part of '../app_shell.dart';

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
