import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
// import '../../../../shared/widgets/design_system.dart';

class CertificateDesignerScreen extends StatefulWidget {
  const CertificateDesignerScreen({
    super.key,
    required this.database,
    required this.projectId,
    required this.projectName,
  });

  final AppDatabase database;
  final String projectId;
  final String projectName;

  @override
  State<CertificateDesignerScreen> createState() =>
      _CertificateDesignerScreenState();
}

class _CertificateDesignerScreenState extends State<CertificateDesignerScreen> {
  final _canvasKey = GlobalKey();
  List<_DesignerField> _fields = [];
  List<String> _columns = [];
  String? _selectedId;
  bool _loading = true;
  bool _saving = false;
  String _saveLabel = 'Not saved';
  final List<List<_DesignerField>> _undoStack = [];
  final List<List<_DesignerField>> _redoStack = [];

  _DesignerField? get _selected =>
      _fields.where((field) => field.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await widget.database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': widget.projectId},
    );
    final students = await widget.database.query(
      DatabaseTables.students,
      where: {'project_id': widget.projectId},
    );
    final columns = <String>{};
    for (final row in students) {
      final raw = row['data_json'];
      if (raw is String) {
        final data = jsonDecode(raw);
        if (data is Map) columns.addAll(data.keys.map((key) => key.toString()));
      }
    }
    if (!mounted) return;
    setState(() {
      _columns = columns.toList()..sort();
      _fields = rows.map(_DesignerField.fromRow).toList();
      _undoStack
        ..clear()
        ..add(List<_DesignerField>.from(_fields));
      _loading = false;
    });
  }

  Future<void> _addField() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => _ColumnPicker(columns: _columns),
    );
    if (source == null || !mounted) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final id = 'field-${DateTime.now().microsecondsSinceEpoch}';
    final field = _DesignerField(
      id: id,
      className: _className(source),
      source: source,
      x: 100,
      y: 100 + (_fields.length * 70),
      width: 420,
      height: 64,
      fontSize: 28,
      color: '#20332B',
    );
    await widget.database.insert(
      DatabaseTables.certificateFields,
      field.toRow(widget.projectId, now),
    );
    if (!mounted) return;
    _updateFields([..._fields, field]);
    setState(() => _selectedId = id);
  }

  Future<void> _deleteSelected() async {
    final selected = _selected;
    if (selected == null) return;
    await widget.database.delete(DatabaseTables.certificateFields, selected.id);
    if (!mounted) return;
    _updateFields(_fields.where((field) => field.id != selected.id).toList());
    setState(() => _selectedId = null);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveLabel = 'Saving...';
    });
    final now = DateTime.now().toUtc().toIso8601String();
    for (final field in _fields) {
      await widget.database.update(
        DatabaseTables.certificateFields,
        field.id,
        field.toRow(widget.projectId, now),
      );
    }
    final layouts = await widget.database.query(
      DatabaseTables.certificateLayouts,
      where: {'project_id': widget.projectId},
    );
    final layout = {
      'project_id': widget.projectId,
      'canvas_width': 1000.0,
      'canvas_height': 700.0,
      'grid_enabled': 1,
      'settings_json': jsonEncode({'updated_by': 'designer'}),
      'updated_at': now,
    };
    if (layouts.isEmpty) {
      await widget.database.insert(DatabaseTables.certificateLayouts, {
        'id': 'layout-${widget.projectId}',
        ...layout,
      });
    } else {
      await widget.database.update(
        DatabaseTables.certificateLayouts,
        layouts.first['id']! as String,
        layout,
      );
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveLabel = 'Saved just now';
    });
  }

  void _moveSelected(DragUpdateDetails details) {
    final selected = _selected;
    if (selected == null) return;
    final next = selected.copyWith(
      x: (selected.x + details.delta.dx).clamp(0, 920),
      y: (selected.y + details.delta.dy).clamp(0, 620),
    );
    _updateFields(
      _fields.map((field) => field.id == next.id ? next : field).toList(),
    );
  }

  void _updateFields(List<_DesignerField> next) {
    if (_sameFields(_fields, next)) return;
    _undoStack.add(List<_DesignerField>.from(_fields));
    _redoStack.clear();
    setState(() {
      _fields = next;
      _saveLabel = 'Unsaved changes';
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<_DesignerField>.from(_fields));
    setState(() {
      _fields = List<_DesignerField>.from(_undoStack.removeLast());
      _selectedId = _fields.any((field) => field.id == _selectedId)
          ? _selectedId
          : null;
      _saveLabel = 'Unsaved changes';
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(List<_DesignerField>.from(_fields));
    setState(() {
      _fields = List<_DesignerField>.from(next);
      _selectedId = _fields.any((field) => field.id == _selectedId)
          ? _selectedId
          : null;
      _saveLabel = 'Unsaved changes';
    });
  }

  bool _sameFields(List<_DesignerField> left, List<_DesignerField> right) =>
      left.length == right.length &&
      left.asMap().entries.every((entry) => entry.value == right[entry.key]);

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: Text('Design · ${widget.projectName}'),
        actions: [
          Text(_saveLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Undo',
            onPressed: _undoStack.length > 1 ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Save design',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 230,
            child: _ElementsPanel(
              columns: _columns,
              fields: _fields,
              selectedId: _selectedId,
              onAdd: _addField,
              onSelect: (id) => setState(() => _selectedId = id),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: _Canvas(
                  fields: _fields,
                  selectedId: _selectedId,
                  canvasKey: _canvasKey,
                  onSelect: (id) => setState(() => _selectedId = id),
                  onMove: _moveSelected,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 280,
            child: _PropertiesPanel(
              field: _selected,
              onChanged: (field) => _updateFields(
                _fields
                    .map((item) => item.id == field.id ? field : item)
                    .toList(),
              ),
              onDelete: _deleteSelected,
            ),
          ),
        ],
      ),
    );
  }

  String _className(String source) => source
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class _ElementsPanel extends StatelessWidget {
  const _ElementsPanel({
    required this.columns,
    required this.fields,
    required this.selectedId,
    required this.onAdd,
    required this.onSelect,
  });
  final List<String> columns;
  final List<_DesignerField> fields;
  final String? selectedId;
  final VoidCallback onAdd;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(right: BorderSide(color: AppColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Elements', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Data field'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Layers', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        if (fields.isEmpty)
          const Text('Add a field from imported data to start designing.'),
        for (final field in fields)
          ListTile(
            selected: field.id == selectedId,
            dense: true,
            leading: const Icon(Icons.text_fields, size: 18),
            title: Text(field.className),
            subtitle: Text(field.source),
            onTap: () => onSelect(field.id),
          ),
      ],
    ),
  );
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.fields,
    required this.selectedId,
    required this.canvasKey,
    required this.onSelect,
    required this.onMove,
  });
  final List<_DesignerField> fields;
  final String? selectedId;
  final GlobalKey canvasKey;
  final ValueChanged<String> onSelect;
  final GestureDragUpdateCallback onMove;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: 1000,
      height: 700,
      child: Container(
        key: canvasKey,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x18000000), blurRadius: 24),
          ],
        ),
        child: Stack(
          children: [
            for (final field in fields)
              Positioned(
                left: field.x,
                top: field.y,
                width: field.width,
                height: field.height,
                child: GestureDetector(
                  onTap: () => onSelect(field.id),
                  onPanUpdate: field.id == selectedId ? onMove : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: field.id == selectedId
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      color: field.id == selectedId
                          ? AppColors.primaryLight.withOpacity(.35)
                          : Colors.transparent,
                    ),
                    alignment: _alignment(field.alignment),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      field.className,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: field.fontSize,
                        color: _hex(field.color),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Alignment _alignment(String value) => switch (value) {
    'center' => Alignment.center,
    'right' => Alignment.centerRight,
    _ => Alignment.centerLeft,
  };
  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({
    required this.field,
    required this.onChanged,
    required this.onDelete,
  });
  final _DesignerField? field;
  final ValueChanged<_DesignerField> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (field == null)
      return const Center(
        child: Text('Select a field to edit its properties.'),
      );
    final selected = field!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        children: [
          Text(
            'Field properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(selected.source, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _NumberInput(
            label: 'X',
            value: selected.x,
            onChanged: (value) => onChanged(selected.copyWith(x: value)),
          ),
          _NumberInput(
            label: 'Y',
            value: selected.y,
            onChanged: (value) => onChanged(selected.copyWith(y: value)),
          ),
          _NumberInput(
            label: 'Width',
            value: selected.width,
            onChanged: (value) => onChanged(selected.copyWith(width: value)),
          ),
          _NumberInput(
            label: 'Height',
            value: selected.height,
            onChanged: (value) => onChanged(selected.copyWith(height: value)),
          ),
          _NumberInput(
            label: 'Font size',
            value: selected.fontSize,
            onChanged: (value) => onChanged(selected.copyWith(fontSize: value)),
          ),
          DropdownButtonFormField<String>(
            value: selected.alignment,
            decoration: const InputDecoration(labelText: 'Alignment'),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(selected.copyWith(alignment: value));
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete field'),
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TextFormField(
      initialValue: value.round().toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    ),
  );
}

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({required this.columns});
  final List<String> columns;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add data field'),
    content: SizedBox(
      width: 360,
      child: columns.isEmpty
          ? const Text(
              'Import student data first so fields can be mapped to columns.',
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final column in columns)
                  ListTile(
                    leading: const Icon(Icons.view_column_outlined),
                    title: Text(column),
                    onTap: () => Navigator.pop(context, column),
                  ),
              ],
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}

class _DesignerField {
  const _DesignerField({
    required this.id,
    required this.className,
    required this.source,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.color,
    this.alignment = 'left',
  });
  final String id;
  final String className;
  final String source;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final String color;
  final String alignment;

  factory _DesignerField.fromRow(Map<String, Object?> row) {
    final position = _decode(row['position_json']);
    final style = _decode(row['style_json']);
    return _DesignerField(
      id: row['id']! as String,
      className: row['class_name']! as String,
      source: (row['source'] as String?) ?? '',
      x: _number(position['x'], 100),
      y: _number(position['y'], 100),
      width: _number(position['width'], 420),
      height: _number(position['height'], 64),
      fontSize: _number(style['font_size'], 28),
      color: (style['color'] as String?) ?? '#20332B',
      alignment: (style['alignment'] as String?) ?? 'left',
    );
  }

  Map<String, Object?> toRow(String projectId, String now) => {
    'id': id,
    'project_id': projectId,
    'class_name': className,
    'source': source,
    'position_json': jsonEncode({
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    }),
    'style_json': jsonEncode({
      'font_size': fontSize,
      'color': color,
      'alignment': alignment,
    }),
    'created_at': now,
    'updated_at': now,
  };
  _DesignerField copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? fontSize,
    String? alignment,
    String? color,
  }) => _DesignerField(
    id: id,
    className: className,
    source: source,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    alignment: alignment ?? this.alignment,
  );
  static Map<String, Object?> _decode(Object? raw) {
    if (raw is! String) return {};
    final value = jsonDecode(raw);
    return value is Map ? Map<String, Object?>.from(value) : {};
  }

  static double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
