import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../template_file_support.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({
    super.key,
    required this.database,
    this.projectId,
  });
  final AppDatabase database;
  final String? projectId;

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  List<Map<String, Object?>> _templates = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = await widget.database.query(DatabaseTables.templates);
    final projects = widget.projectId == null ? const <Map<String, Object?>>[] : await widget.database.query(DatabaseTables.projects, where: {'id': widget.projectId});
    if (!mounted) return;
    setState(() {
      _templates = templates;
      _selectedId = projects.isEmpty
          ? null
          : projects.first['template_id'] as String?;
      _loading = false;
    });
  }

  Future<void> _addTemplate() async {
    final draft = await showDialog<_TemplateDraft>(
      context: context,
          builder: (_) => const _TemplateDialog(),
    );
    if (draft == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await widget.database.insert(DatabaseTables.templates, {
      'id': 'template-${DateTime.now().microsecondsSinceEpoch}',
      'name': draft.name,
      'file_path': draft.path,
      'width': draft.width,
      'height': draft.height,
      'dpi': draft.dpi,
      'format': draft.format,
      'created_at': now,
      'updated_at': now,
    });
    await _load();
  }

  Future<void> _select(String id) async {
    if (widget.projectId != null) {
      await widget.database.update(DatabaseTables.projects, widget.projectId!, {
        'template_id': id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    if (mounted) setState(() => _selectedId = id);
  }

  Future<void> _delete(String id) async {
    final linked = await widget.database.query(
      DatabaseTables.projects,
      where: {'template_id': id},
    );
    if (linked.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This template is used by a project and cannot be deleted.',
          ),
        ),
      );
      return;
    }
    await widget.database.delete(DatabaseTables.templates, id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final projectMode = widget.projectId != null;
    return Scaffold(
      appBar: AppBar(title: Text(projectMode ? 'Certificate template' : 'Templates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectMode ? 'Choose a certificate template' : 'Template library',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  projectMode ? 'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.' : 'Browse persisted certificate backgrounds or import a new template.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _addTemplate,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(context.l10n.text('Add template')),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_templates.isEmpty)
                  const AppSurfaceCard(
                    child: Text(
                      'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.',
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 280,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                    itemCount: _templates.length,
                    itemBuilder: (_, index) {
                      final template = _templates[index];
                      return _TemplateCard(
                        template: template,
                        selected: template['id'] == _selectedId,
                        onSelect: () => _select(template['id']! as String),
                        onDelete: () => _delete(template['id']! as String),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });
  final Map<String, Object?> template;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final path = template['file_path'] as String? ?? '';
    final exists = templateFileExists(path);
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: exists ? templatePreview(path) : const _MissingPreview(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            template['name']! as String,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${template['width']} × ${template['height']} · ${template['format'].toString().toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!exists)
            Text(
              'File not found at saved path',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 11,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: selected
                    ? const Text(
                        'Selected',
                        style: TextStyle(color: Colors.green),
                      )
                    : TextButton(
                        onPressed: onSelect,
                        child: Text(context.l10n.text('Use template')),
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
  const _TemplateDialog();
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
  void dispose() {
    _name.dispose();
    _path.dispose();
    _width.dispose();
    _height.dispose();
    _dpi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.text('Add template')),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field(_name, 'Template name'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      _path,
                      'Background image',
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
                  Expanded(child: _field(_width, 'Width', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_height, 'Height', number: true)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field(_dpi, 'DPI', number: true)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _format,
                      decoration: InputDecoration(labelText: context.l10n.text('Format')),
                      items: const [
                        DropdownMenuItem(value: 'png', child: Text(context.l10n.text('PNG'))),
                        DropdownMenuItem(value: 'jpg', child: Text(context.l10n.text('JPG'))),
                        DropdownMenuItem(value: 'webp', child: Text(context.l10n.text('WEBP'))),
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
          (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    ),
  );
}
