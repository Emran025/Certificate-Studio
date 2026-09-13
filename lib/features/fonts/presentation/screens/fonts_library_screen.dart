import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';

class FontsLibraryScreen extends StatefulWidget {
  const FontsLibraryScreen({super.key, required this.database, this.projectId});
  final AppDatabase database;
  final String? projectId;
  @override
  State<FontsLibraryScreen> createState() => _FontsLibraryScreenState();
}

class _FontsLibraryScreenState extends State<FontsLibraryScreen> {
  List<Map<String, Object?>> _fonts = const [];
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fonts = await widget.database.query(DatabaseTables.fonts);
    final projects = widget.projectId == null ? const <Map<String, Object?>>[] : await widget.database.query(DatabaseTables.projects, where: {'id': widget.projectId});
    final settings = projects.isEmpty ? const <String, dynamic>{} : _decode(projects.first['settings_json']);
    if (mounted) setState(() { _fonts = fonts.reversed.toList(); _selectedId = settings['font_id']?.toString(); _loading = false; });
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ttf', 'otf', 'woff', 'woff2'], withData: false);
    final file = result?.files.single;
    final path = file?.path;
    if (file == null || path == null || path.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final name = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final format = file.extension?.toLowerCase() ?? 'ttf';
    await widget.database.insert(DatabaseTables.fonts, {'id': 'font-${DateTime.now().microsecondsSinceEpoch}', 'name': name, 'family': name, 'file_path': path, 'format': format, 'created_at': now, 'updated_at': now});
    await _load();
  }

  Future<void> _delete(String id) async {
    await widget.database.delete(DatabaseTables.fonts, id);
    await _load();
  }

  Future<void> _use(String id) async {
    if (widget.projectId == null) return;
    final projects = await widget.database.query(DatabaseTables.projects, where: {'id': widget.projectId});
    if (projects.isEmpty) return;
    final settings = _decode(projects.first['settings_json']);
    settings['font_id'] = id;
    await widget.database.update(DatabaseTables.projects, widget.projectId!, {'settings_json': jsonEncode(settings), 'updated_at': DateTime.now().toUtc().toIso8601String()});
    if (mounted) setState(() => _selectedId = id);
  }

  Map<String, dynamic> _decode(Object? raw) => raw is String && raw.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : <String, dynamic>{};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fonts')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import font')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Font library', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('${_fonts.length} persisted font${_fonts.length == 1 ? '' : 's'} available to projects.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _fonts.isEmpty ? SizedBox(width: double.infinity, child: AppSurfaceCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('No fonts have been imported yet.'), const SizedBox(height: AppSpacing.md), FilledButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import font'))]))) : ListView.separated(itemCount: _fonts.length, separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm), itemBuilder: (_, index) { final font = _fonts[index]; final id = font['id']! as String; final selected = id == _selectedId; return AppSurfaceCard(child: ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.text_fields)), title: Text(font['name']?.toString() ?? 'Unnamed font'), subtitle: Text('${font['family']} · ${font['format'].toString().toUpperCase()}\n${font['file_path']}'), isThreeLine: true, trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (widget.projectId != null) TextButton(onPressed: selected ? null : () => _use(id), child: Text(selected ? 'In use' : 'Use')), IconButton(tooltip: 'Delete', onPressed: () => _delete(id), icon: const Icon(Icons.delete_outline))]))); })),
      ])),
    ),
  );
}
