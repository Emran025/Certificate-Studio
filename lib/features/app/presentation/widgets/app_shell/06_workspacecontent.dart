part of '../app_shell.dart';

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
                    final compact =
                        constraints.maxWidth < AppBreakpoints.tablet;
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
