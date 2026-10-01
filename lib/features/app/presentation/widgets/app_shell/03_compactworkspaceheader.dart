part of '../app_shell.dart';

class _CompactWorkspaceHeader extends StatelessWidget {
  const _CompactWorkspaceHeader({required this.onOpenDrawer});

  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.themeBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onOpenDrawer,
              tooltip: context.l10n.text('Open navigation'),
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: AppSpacing.xs),
            const AppBrandLogo(size: 32),
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
      ),
    );
  }
}
