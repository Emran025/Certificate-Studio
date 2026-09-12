import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key, required this.database, required this.projectId});
  final AppDatabase database;
  final String projectId;
  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  List<Map<String, Object?>> _templates = [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final templates = await widget.database.query(DatabaseTables.templates); final projects = await widget.database.query(DatabaseTables.projects, where: {'id': widget.projectId}); if (!mounted) return; setState(() { _templates = templates; _selectedId = projects.isEmpty ? null : projects.first['template_id'] as String?; _loading = false; }); }

  Future<void> _addTemplate() async {
    final result = await showDialog<_TemplateDraft>(context: context, builder: (_) => const _TemplateDialog());
    if (result == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await widget.database.insert(DatabaseTables.templates, {'id': 'template-${DateTime.now().microsecondsSinceEpoch}', 'name': result.name, 'file_path': result.path, 'width': result.width, 'height': result.height, 'dpi': result.dpi, 'format': result.format, 'created_at': now, 'updated_at': now});
    await _load();
  }

  Future<void> _select(String id) async { await widget.database.update(DatabaseTables.projects, widget.projectId, {'template_id': id, 'updated_at': DateTime.now().toUtc().toIso8601String()}); if (mounted) setState(() => _selectedId = id); }
  Future<void> _delete(String id) async { final linked = await widget.database.query(DatabaseTables.projects, where: {'template_id': id}); if (linked.isNotEmpty && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This template is used by a project and cannot be deleted.'))); return; } await widget.database.delete(DatabaseTables.templates, id); await _load(); }

  @override
  Widget build(BuildContext context) { if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator())); return Scaffold(appBar: AppBar(title: const Text('Certificate template')), body: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 920), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choose a certificate template', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: AppSpacing.xs), Text('Reuse a saved background or register a new local image file.', style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: AppSpacing.lg), Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _addTemplate, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Add template'))), const SizedBox(height: AppSpacing.lg), if (_templates.isEmpty) const AppSurfaceCard(child: Text('No templates saved yet. Add a PNG, JPG, WEBP, or PDF background to continue.')) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, mainAxisExtent: 220, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md), itemCount: _templates.length, itemBuilder: (_, index) => _TemplateCard(template: _templates[index], selected: _templates[index]['id'] == _selectedId, onSelect: () => _select(_templates[index]['id']! as String), onDelete: () => _delete(_templates[index]['id']! as String)))])))); }
}

class _TemplateCard extends StatelessWidget { const _TemplateCard({required this.template, required this.selected, required this.onSelect, required this.onDelete}); final Map<String, Object?> template; final bool selected; final VoidCallback onSelect; final VoidCallback onDelete; @override Widget build(BuildContext context) => AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, size: 48))), const SizedBox(height: AppSpacing.sm), Text(template['name']! as String, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis), Text('${template['width']} × ${template['height']} · ${template['format']}', style: Theme.of(context).textTheme.bodySmall), Row(children: [Expanded(child: selected ? const Text('Selected', style: TextStyle(color: Colors.green)) : TextButton(onPressed: onSelect, child: const Text('Use template'))), IconButton(tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete_outline))]) ])); }

class _TemplateDraft { const _TemplateDraft({required this.name, required this.path, required this.width, required this.height, required this.dpi, required this.format}); final String name; final String path; final int width; final int height; final double dpi; final String format; }
class _TemplateDialog extends StatefulWidget { const _TemplateDialog(); @override State<_TemplateDialog> createState() => _TemplateDialogState(); }
class _TemplateDialogState extends State<_TemplateDialog> { final _formKey = GlobalKey<FormState>(); final _name = TextEditingController(); final _path = TextEditingController(); final _width = TextEditingController(text: '1920'); final _height = TextEditingController(text: '1080'); final _dpi = TextEditingController(text: '300'); String _format = 'png'; @override Widget build(BuildContext context) => AlertDialog(title: const Text('Add template'), content: SizedBox(width: 440, child: Form(key: _formKey, child: SingleChildScrollView(child: Column(children: [_field(_name, 'Template name'), _field(_path, 'Local file path'), Row(children: [Expanded(child: _field(_width, 'Width', number: true)), const SizedBox(width: 8), Expanded(child: _field(_height, 'Height', number: true))]), Row(children: [Expanded(child: _field(_dpi, 'DPI', number: true)), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<String>(value: _format, decoration: const InputDecoration(labelText: 'Format'), items: const [DropdownMenuItem(value: 'png', child: Text('PNG')), DropdownMenuItem(value: 'jpg', child: Text('JPG')), DropdownMenuItem(value: 'webp', child: Text('WEBP')), DropdownMenuItem(value: 'pdf', child: Text('PDF'))], onChanged: (value) => setState(() => _format = value ?? 'png')))])])))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (!_formKey.currentState!.validate()) return; Navigator.pop(context, _TemplateDraft(name: _name.text.trim(), path: _path.text.trim(), width: int.parse(_width.text), height: int.parse(_height.text), dpi: double.parse(_dpi.text), format: _format)); }, child: const Text('Save'))]);
 Widget _field(TextEditingController controller, String label, {bool number = false}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: controller, keyboardType: number ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null)); }
