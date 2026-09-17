import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(label),
            ],
          );
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(label),
            ],
          );
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: context.themeBorder),
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              hoverColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.06),
              splashColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color ?? scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.themeSelection,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Icon(icon, color: context.themePrimary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < actions!.length; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  actions![index],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.icon,
    this.subtitle,
    this.width,
    this.showCloseButton = false,
  });

  final Widget title;
  final Widget child;
  final List<Widget>? actions;
  final IconData? icon;
  final Widget? subtitle;
  final double? width;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = Color.alphaBlend(
      (isDark ? Colors.black : Colors.black).withValues(
        alpha: isDark ? 0.18 : 0.06,
      ),
      theme.colorScheme.surface,
    );
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: isDark ? Colors.white : theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width == null ? 280 : 0,
          maxWidth: width ?? 600,
          maxHeight: MediaQuery.sizeOf(context).height - AppSpacing.xl * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: headerColor,
                border: Border(bottom: BorderSide(color: context.themeBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: context.themePrimary),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(style: titleStyle!, child: title),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            DefaultTextStyle(
                              style: theme.textTheme.bodySmall!,
                              child: subtitle!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var index = 0; index < actions!.length; index++) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.sm),
                      actions![index],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppPageTable extends StatelessWidget {
  const AppPageTable({super.key, required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.themeSurface,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.themeBackground,
          border: Border.all(color: context.themeBorder),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.themeBorder),
                  ),
                ),
                child: header,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
