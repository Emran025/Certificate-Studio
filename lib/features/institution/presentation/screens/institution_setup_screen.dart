import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/institution_repository_impl.dart';
import '../../domain/entities/institution.dart';

class InstitutionSetupScreen extends StatefulWidget {
  const InstitutionSetupScreen({
    super.key,
    required this.repository,
    required this.keyManager,
    required this.onCompleted,
  });

  final InstitutionRepositoryImpl repository;
  final InstitutionKeyManager keyManager;
  final ValueChanged<Institution> onCompleted;

  @override
  State<InstitutionSetupScreen> createState() => _InstitutionSetupScreenState();
}

class _InstitutionSetupScreenState extends State<InstitutionSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now().toUtc();
      final institution = Institution(
        id: 'institution-${now.microsecondsSinceEpoch}',
        institutionId: _slugify(
          _nameEnController.text.trim().isEmpty
              ? _nameController.text.trim()
              : _nameEnController.text.trim(),
        ),
        name: _nameController.text.trim(),
        nameAr: _optional(_nameArController.text),
        nameEn: _optional(_nameEnController.text),
        contact: {'contact': _contactController.text.trim()},
        settings: const {'setup_complete': true},
        createdAt: now,
        updatedAt: now,
      );
      await widget.repository.save(institution);
      await widget.keyManager.initialize();
      if (mounted) widget.onCompleted(institution);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'We could not save your institution. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppSurfaceCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Set up your institution',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'This information is used to identify your certificates and verification records.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('Institution name *'),
                        hintText: context.l10n.text('e.g. Al-Noor Academy'),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameArController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('Arabic name'),
                        hintText: context.l10n.text('اسم المؤسسة'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameEnController,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('English name'),
                        hintText: context.l10n.text('Institution name'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('Contact information'),
                        hintText: context.l10n.text('Email, phone, or website'),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: _isSaving
                            ? 'Saving...'
                            : 'Continue to workspace',
                        icon: _isSaving ? null : Icons.arrow_forward,
                        onPressed: _isSaving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Institution name is required.'
      : null;

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  String _slugify(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty
        ? 'institution-${DateTime.now().millisecondsSinceEpoch}'
        : slug;
  }
}
