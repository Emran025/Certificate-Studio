part of '../app_shell.dart';

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
