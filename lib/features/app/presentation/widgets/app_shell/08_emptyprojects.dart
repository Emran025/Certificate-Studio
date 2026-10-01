part of '../app_shell.dart';

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
                    'Start with project information, then add a template and record data.',
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
