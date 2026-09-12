import 'package:flutter/material.dart';

import 'config/env/app_environment.dart';
import 'shared/themes/app_colors.dart';
import 'shared/themes/app_spacing.dart';
import 'shared/themes/app_theme.dart';
import 'shared/widgets/design_system.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CertificateStudioApp());
}

class CertificateStudioApp extends StatelessWidget {
  const CertificateStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppEnvironment.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale(AppEnvironment.defaultLocale),
      supportedLocales: AppEnvironment.supportedLocales
          .map((languageCode) => Locale(languageCode))
          .toList(),
      home: const WorkspaceShell(),
    );
  }
}

class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            const _WorkspaceNavigation(),
            Expanded(child: _WorkspaceContent()),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_outlined, color: Colors.white, size: 21),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(AppEnvironment.appName, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _NavigationItem(icon: Icons.home_outlined, label: 'Home', selected: true),
          const _NavigationItem(icon: Icons.folder_outlined, label: 'Projects'),
          const _NavigationItem(icon: Icons.image_outlined, label: 'Templates'),
          const _NavigationItem(icon: Icons.text_fields_outlined, label: 'Fonts'),
          const _NavigationItem(icon: Icons.workspace_premium_outlined, label: 'Certificates'),
          const Spacer(),
          const _NavigationItem(icon: Icons.verified_user_outlined, label: 'Verification'),
          const _NavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.icon, required this.label, this.selected = false});

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            leading: Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
            title: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? AppColors.primary : AppColors.textSecondary)),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.page),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Create and manage your certificates', style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Notifications', onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined)),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(tooltip: 'Settings', onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: AppPrimaryButton(label: 'New project', icon: Icons.add, onPressed: () {})),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppSecondaryButton(label: 'Import project', icon: Icons.file_upload_outlined, onPressed: () {})),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const AppSectionHeader(title: 'Recent projects'),
              const SizedBox(height: AppSpacing.md),
              const _ProjectPreviewCard(title: 'Flutter Advanced Course 2026', metadata: '24 certificates  •  Updated 2 hours ago', status: 'Configured'),
              const SizedBox(height: AppSpacing.sm),
              const _ProjectPreviewCard(title: 'English Training Program', metadata: '41 certificates  •  Updated yesterday', status: 'Draft', statusColor: AppColors.warning, statusBackground: AppColors.warningSurface),
              const SizedBox(height: AppSpacing.xxl),
              const AppSectionHeader(title: 'Your workspace'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: const [
                  Expanded(child: _MetricCard(icon: Icons.image_outlined, value: '0', label: 'Templates')),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _MetricCard(icon: Icons.text_fields_outlined, value: '0', label: 'Fonts')),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: _MetricCard(icon: Icons.workspace_premium_outlined, value: '0', label: 'Certificates')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectPreviewCard extends StatelessWidget {
  const _ProjectPreviewCard({required this.title, required this.metadata, required this.status, this.statusColor = AppColors.success, this.statusBackground = AppColors.successSurface});

  final String title;
  final String metadata;
  final String status;
  final Color statusColor;
  final Color statusBackground;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppRadius.input)), child: const Icon(Icons.description_outlined, color: AppColors.primary)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(padding: const EdgeInsets.only(top: AppSpacing.xxs), child: Text(metadata)),
        trailing: AppStatusBadge(label: status, color: statusColor, backgroundColor: statusBackground),
        onTap: () {},
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineMedium), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))])]),
    );
  }
}

// Backwards-compatible alias for the starter test and existing consumers.
typedef MyApp = CertificateStudioApp;
