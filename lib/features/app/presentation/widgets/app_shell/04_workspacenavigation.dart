part of '../app_shell.dart';

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.selected,
    this.onHome,
    this.onProjects,
    this.onTemplates,
    this.onFonts,
    this.onCertificates,
    this.onVerification,
    this.onSettings,
  });

  final String selected;
  final VoidCallback? onHome;
  final VoidCallback? onProjects;
  final VoidCallback? onTemplates;
  final VoidCallback? onFonts;
  final VoidCallback? onCertificates;
  final VoidCallback? onVerification;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        gradient: context.themeSidebarGradient,
        border: Border(right: BorderSide(color: context.themeBorder)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBrandLogo(size: 36, borderRadius: 10),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.text(AppEnvironment.appNameKey),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _NavigationItem(
            icon: Icons.home_outlined,
            label: context.l10n.text('home'),
            selected: selected == 'home',
            onTap: onHome,
          ),
          _NavigationItem(
            icon: Icons.folder_outlined,
            label: context.l10n.text('projects'),
            selected: selected == 'projects',
            onTap: onProjects,
          ),
          _NavigationItem(
            icon: Icons.image_outlined,
            label: context.l10n.text('templates'),
            selected: selected == 'templates',
            onTap: onTemplates,
          ),
          _NavigationItem(
            icon: Icons.text_fields_outlined,
            label: context.l10n.text('fonts'),
            selected: selected == 'fonts',
            onTap: onFonts,
          ),
          _NavigationItem(
            icon: Icons.workspace_premium_outlined,
            label: context.l10n.text('certificates'),
            selected: selected == 'certificates',
            onTap: onCertificates,
          ),
          const Spacer(),
          _NavigationItem(
            icon: Icons.verified_user_outlined,
            label: context.l10n.text('verification'),
            selected: selected == 'verification',
            onTap: onVerification,
          ),
          _NavigationItem(
            icon: Icons.settings_outlined,
            label: context.l10n.text('settings'),
            selected: selected == 'settings',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}
