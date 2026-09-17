import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/template_repository_impl.dart';
import '../../domain/entities/template_asset.dart';
import '../bloc/template_picker_bloc.dart';
import '../template_file_support.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({
    super.key,
    required this.database,
    this.projectId,
  });
  final AppDatabase database;
  final String? projectId;

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
        TemplatePickerBloc(TemplateRepositoryImpl(database), projectId)
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
    required this.projectMode,
  });
  final TemplateAsset template;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool projectMode;

  @override
  Widget build(BuildContext context) {
    final path = template.filePath;
    final exists = templateFileExists(path);
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: exists ? templatePreview(path) : const _MissingPreview(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${template.width} × ${template.height} · ${template.format.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!exists)
                  Text(
                    context.l10n.text('File not found at saved path'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: projectMode && selected
                          ? Text(
                              context.l10n.text('Selected'),
                              style: TextStyle(color: Colors.green),
                            )
                          : projectMode
                          ? TextButton(
                              onPressed: onSelect,
                              child: Text(context.l10n.text('Use template')),
                            )
                          : TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(context.l10n.text('Edit template')),
                            ),
                    ),
                    IconButton(
                      tooltip: context.l10n.text('Delete'),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPreview extends StatelessWidget {
  const _MissingPreview();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 40),
    ),
  );
}

class _TemplateDraft {
  const _TemplateDraft({
    required this.name,
    required this.path,
    required this.width,
    required this.height,
    required this.dpi,
    required this.format,
  });
  final String name;
  final String path;
  final int width;
  final int height;
  final double dpi;
  final String format;
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.initial});
  final TemplateAsset? initial;
  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _path = TextEditingController();
  String? _selectedFileName;
  final _width = TextEditingController(text: '1920');
  final _height = TextEditingController(text: '1080');
  final _dpi = TextEditingController(text: '300');
  String _format = 'png';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name;
      _path.text = initial.filePath;
      _width.text = initial.width.toString();
      _height.text = initial.height.toString();
      _dpi.text = initial.dpi.toString();
      _format = initial.format;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    _width.dispose();
    _height.dispose();
    _dpi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDialog(
    title: Text(
      context.l10n.text(
        widget.initial == null ? 'Add template' : 'Edit template',
      ),
    ),
    icon: widget.initial == null
        ? Icons.add_photo_alternate_outlined
        : Icons.edit_outlined,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.text('Cancel')),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _TemplateDraft(
              name: _name.text.trim(),
              path: _path.text.trim(),
              width: int.parse(_width.text),
              height: int.parse(_height.text),
              dpi: double.parse(_dpi.text),
              format: _format,
            ),
          );
        },
        child: Text(context.l10n.text('Save')),
      ),
    ],
    child: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field(context, _name, context.l10n.text('Template name')),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _path,
                      context.l10n.text('Background image'),
                      readOnly: true,
                      validator: (value) => validateTemplatePath(value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: _chooseBackground,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(context.l10n.text('Choose image')),
                    ),
                  ),
                ],
              ),
              if (_selectedFileName != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedFileName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _width,
                      context.l10n.text('Width'),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      context,
                      _height,
                      context.l10n.text('Height'),
                      number: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      context,
                      _dpi,
                      context.l10n.text('DPI'),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _format,
                      decoration: InputDecoration(
                        labelText: context.l10n.text('Format'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'png',
                          child: Text(context.l10n.text('PNG')),
                        ),
                        DropdownMenuItem(
                          value: 'jpg',
                          child: Text(context.l10n.text('JPG')),
                        ),
                        DropdownMenuItem(
                          value: 'webp',
                          child: Text(context.l10n.text('WEBP')),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _format = value ?? 'png'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _chooseBackground() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final file = result?.files.single;
    final path = file?.path;
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _path.text = path;
      _selectedFileName = file!.name;
      final extension = file.extension?.toLowerCase();
      if (extension == 'jpg' || extension == 'jpeg') {
        _format = 'jpg';
      } else if (extension == 'webp') {
        _format = 'webp';
      } else {
        _format = 'png';
      }
    });
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool number = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? context.l10n.text('Required')
              : null,
    ),
  );
}
