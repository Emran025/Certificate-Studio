part of '../projects_library_screen.dart';

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onTap,
    required this.onGenerate,
    required this.onDelete,
  });
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onGenerate;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.folder_outlined)),
          title: Text(project.name),
          subtitle: Text(
            [
              if (project.courseName?.isNotEmpty == true) project.courseName!,
              if (project.organizationName?.isNotEmpty == true)
                project.organizationName!,
              context.l10n.text('createdDate', {
                'date':
                    '${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
              }),
            ].join(' · '),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.l10n.text(
                  'Generate and create verification records',
                ),
                onPressed: onGenerate,
                icon: const Icon(Icons.verified_outlined),
              ),
              IconButton(
                tooltip: context.l10n.text('Delete project'),
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}
