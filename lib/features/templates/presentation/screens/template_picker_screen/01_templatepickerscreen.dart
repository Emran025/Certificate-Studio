part of '../template_picker_screen.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({
    super.key,
    required this.database,
    this.projectId,
    this.onBack,
  });
  final AppDatabase database;
  final String? projectId;
  final VoidCallback? onBack;

  Future<void> _addTemplate(BuildContext context) async {
    final bloc = context.read<TemplatePickerBloc>();
    final draft = await showDialog<_TemplateDraft>(
      context: context,
      builder: (_) => const _TemplateDialog(),
    );
    if (draft == null) return;
    bloc.add(
      TemplateAdded(
        TemplateAsset(
          id: 'template-${DateTime.now().microsecondsSinceEpoch}',
          name: draft.name,
          filePath: draft.path,
          width: draft.width,
          height: draft.height,
          dpi: draft.dpi,
          format: draft.format,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TemplatePickerBloc(TemplateRepositoryImpl(TemplateDataSourceImpl(database)), projectId)
          ..add(const TemplatesRequested()),
    child: BlocBuilder<TemplatePickerBloc, TemplatePickerState>(
      builder: (context, state) {
        if (state.status == TemplatePickerStatus.loading ||
            state.status == TemplatePickerStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final projectMode = projectId != null;
        return Scaffold(
          body: AppPageTable(
            header: AppPageHeader(
              title: projectMode
                  ? context.l10n.text('Choose a certificate template')
                  : context.l10n.text('Template library'),
              subtitle: projectMode
                  ? context.l10n.text(
                      'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.',
                    )
                  : context.l10n.text(
                      'Browse persisted certificate backgrounds or import a new template.',
                    ),
              icon: Icons.image_outlined,
              actions: [
                if (projectMode)
                  IconButton(
                    tooltip: context.l10n.text('back'),
                    onPressed: onBack ?? () => Navigator.of(context).pop(),
                    icon: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward
                          : Icons.arrow_back,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: () => _addTemplate(context),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(context.l10n.text('Add template')),
                ),
              ],
            ),
            child: state.templates.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        context.l10n.text(
                          'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.',
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < AppBreakpoints.tablet;
                      final columns = compact
                          ? 1
                          : (constraints.maxWidth / 300).floor().clamp(1, 4);
                      return GridView.builder(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.sm : AppSpacing.xl,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: compact ? 360 : 280,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        itemCount: state.templates.length,
                        itemBuilder: (_, index) {
                          final template = state.templates[index];
                          return _TemplateCard(
                            template: template,
                            selected: template.id == state.selectedId,
                            onSelect: () => context
                                .read<TemplatePickerBloc>()
                                .add(TemplateSelected(template.id)),
                            onDelete: () => context
                                .read<TemplatePickerBloc>()
                                .add(TemplateDeleted(template.id)),
                            onEdit: () async {
                              final draft = await showDialog<_TemplateDraft>(
                                context: context,
                                builder: (_) =>
                                    _TemplateDialog(initial: template),
                              );
                              if (draft == null || !context.mounted) return;
                              context.read<TemplatePickerBloc>().add(
                                TemplateUpdated(
                                  TemplateAsset(
                                    id: template.id,
                                    name: draft.name,
                                    filePath: draft.path,
                                    width: draft.width,
                                    height: draft.height,
                                    dpi: draft.dpi,
                                    format: draft.format,
                                  ),
                                ),
                              );
                            },
                            projectMode: projectMode,
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
    ),
  );
}
