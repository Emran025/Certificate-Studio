import '../../../../config/localization/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/usecases/create_project.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({
    super.key,
    required this.institutionId,
    required this.createProject,
  });

  final String institutionId;
  final CreateProject createProject;

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _courseController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _projectType = 'course';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _courseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final project = await widget.createProject(
        CreateProjectParams(
          name: _nameController.text,
          institutionId: widget.institutionId,
          organizationName: _organizationController.text,
          courseName: _courseController.text,
          description: _descriptionController.text,
          projectType: _projectType,
        ),
      );
      if (mounted) Navigator.of(context).pop(project);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'We could not create this project. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('Create new project')),
        leading: IconButton(
          tooltip: context.l10n.text('Close'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      color: AppColors.primaryLight,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: AppColors.textOnPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.text('Project information'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  context.l10n.text(
                                    'Set up the context for this certificate-issuing project. You can configure templates and data next.',
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: context.l10n.text('Project name *'),
                              hintText: context.l10n.text(
                                'e.g. Flutter Advanced Course 2026',
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? context.l10n.text('Project name is required.')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _organizationController,
                            decoration: InputDecoration(
                              labelText: context.l10n.text('Organization'),
                              hintText: context.l10n.text(
                                'Academy or institution name',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _courseController,
                            decoration: InputDecoration(
                              labelText: context.l10n.text('Course or program'),
                              hintText: context.l10n.text(
                                'e.g. Flutter Advanced',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: context.l10n.text('Description'),
                              hintText: context.l10n.text(
                                'Optional project notes',
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.l10n.text('Certificate type'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  for (final type in const {
                                    'course': 'Course',
                                    'training': 'Training',
                                    'achievement': 'Achievement',
                                    'participation': 'Participation',
                                    'custom': 'Custom',
                                  }.entries)
                                    ChoiceChip(
                                      avatar: Icon(
                                        _projectType == type.key
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 16,
                                      ),
                                      label: Text(context.l10n.text(type.value)),
                                      selected: _projectType == type.key,
                                      onSelected: (_) => setState(
                                        () => _projectType = type.key,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              context.l10n.text(_errorMessage!),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppSecondaryButton(
                                label: context.l10n.text('Cancel'),
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              AppPrimaryButton(
                                label: _isSaving
                                    ? context.l10n.text('Creating...')
                                    : context.l10n.text('Continue'),
                                icon: _isSaving ? null : Icons.arrow_forward,
                                onPressed: _isSaving ? null : _create,
                              ),
                            ],
                          ),
                        ],
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
}
