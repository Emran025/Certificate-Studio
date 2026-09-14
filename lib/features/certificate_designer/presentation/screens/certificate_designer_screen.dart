import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../certificate_generation/domain/template_bytes.dart';
import '../../../../features/templates/presentation/template_file_support.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/utils/field_identifier.dart';

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
  List<_DesignerField> _fields = [];
  List<String> _columns = [];
  Map<String, dynamic> _previewData = {};
  Map<String, Object?>? _template;
  String? _selectedId;
  bool _loading = true;
  bool _saving = false;
  String _saveLabel = 'Not saved';
  final Set<String> _loadedFontFamilies = {};
  String _projectFontFamily = 'Cairo';
  List<String> _fontFamilies = const ['Cairo', 'Arial', 'sans-serif'];
  double _zoom = 0.85;
  final List<List<_DesignerField>> _undoStack = [];
  final List<List<_DesignerField>> _redoStack = [];

  _DesignerField? get _selected =>
      _fields.where((field) => field.id == _selectedId).firstOrNull;
  double get _canvasWidth => _number(_template?['width'], 1000);
  double get _canvasHeight => _number(_template?['height'], 700);
  String get _templatePath => _template?['file_path'] as String? ?? '';

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
    final projects = await widget.database.query(
      DatabaseTables.projects,
      where: {'id': widget.projectId},
    );
    final projectTemplateId = projects.firstOrNull?['template_id'] as String?;
    final projectSettings = _decodeMap(projects.firstOrNull?['settings_json']);
    final projectFontId = projectSettings['font_id']?.toString();
    final projectFonts = projectFontId == null ? const <Map<String, Object?>>[] : await widget.database.query(DatabaseTables.fonts, where: {'id': projectFontId});
    final fontRows = await widget.database.query(DatabaseTables.fonts);
    await _registerImportedFonts(fontRows);
    final templates = projectTemplateId == null
        ? <Map<String, Object?>>[]
        : await widget.database.query(
            DatabaseTables.templates,
            where: {'id': projectTemplateId},
          );
    final columns = <String>{};
    Map<String, dynamic> preview = {};
    for (final row in students) {
      final raw = row['data_json'];
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          columns.addAll(data.keys);
          if (preview.isEmpty) preview = data;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _columns = columns.toList()..sort();
      _previewData = preview;
      _template = templates.firstOrNull;
      _projectFontFamily = projectFonts.firstOrNull?['family']?.toString() ?? 'Cairo';
      _fontFamilies = {
        'Cairo',
        'Arial',
        'sans-serif',
        for (final font in fontRows)
          if (font['family']?.toString().trim().isNotEmpty ?? false)
            font['family']!.toString(),
        _projectFontFamily,
      }.toList();
      _fields = rows.map(_DesignerField.fromRow).toList();
      _undoStack
        ..clear()
        ..add(List<_DesignerField>.from(_fields));
      _loading = false;
    });
  }

  Future<void> _registerImportedFonts(
    List<Map<String, Object?>> rows,
  ) async {
    for (final row in rows) {
      final family = row['family']?.toString().trim();
      if (family == null ||
          family.isEmpty ||
          _loadedFontFamilies.contains(family)) {
        continue;
      }
      final storedBytes = row['font_bytes'];
      final path = row['file_path']?.toString().trim() ?? '';
      final bytes = storedBytes is List
          ? List<int>.from(storedBytes)
          : await readTemplateBytes(path);
      if (bytes == null || bytes.isEmpty) continue;
      try {
        final loader = FontLoader(family)
          ..addFont(
            Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
          );
        await loader.load();
        _loadedFontFamilies.add(family);
      } on Object {
        // Keep the font selectable for PDF fallback even when Flutter cannot
        // load its format; one invalid font must not block the designer.
      }
    }
  }

  Future<void> _addField() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => _ColumnPicker(columns: _columns),
    );
    if (source == null || !mounted) return;
    final id = 'field-${DateTime.now().microsecondsSinceEpoch}';
    final field = _DesignerField(
      id: id,
      className: canonicalFieldClassId(source),
      source: source,
      x: ((_canvasWidth - 420) / 2).clamp(0, _canvasWidth - 120).toDouble(),
      y: (100 + (_fields.length * 70)).clamp(0, _canvasHeight - 64).toDouble(),
      width: 420.clamp(120, _canvasWidth).toDouble(),
      height: 64.clamp(40, _canvasHeight).toDouble(),
      fontSize: 28,
      color: '#20332B',
      fontFamily: _projectFontFamily,
    );
    await widget.database.insert(
      DatabaseTables.certificateFields,
      field.toRow(widget.projectId, DateTime.now().toUtc().toIso8601String()),
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

  Future<void> _addQrField() async {
    final id = 'qr-${DateTime.now().microsecondsSinceEpoch}';
    const size = 220.0;
    final field = _DesignerField(
      id: id,
      className: 'qr_code',
      source: '',
      x: (_canvasWidth - size - 40).clamp(0, _canvasWidth - size).toDouble(),
      y: (_canvasHeight - size - 40).clamp(0, _canvasHeight - size).toDouble(),
      width: size,
      height: size,
      fontSize: 0,
      color: '#000000',
      qr: true,
    );
    await widget.database.insert(DatabaseTables.certificateFields,
        field.toRow(widget.projectId, DateTime.now().toUtc().toIso8601String()));
    if (!mounted) return;
    _updateFields([..._fields, field]);
    setState(() => _selectedId = id);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveLabel = 'Saving...';
    });
    final now = DateTime.now().toUtc().toIso8601String();
    widget.database.beginBatch();
    try {
      for (final field in _fields) {
        await widget.database.update(
          DatabaseTables.certificateFields,
          field.id,
          field.toRow(widget.projectId, now),
        );
      }
      await widget.database.upsert(
        DatabaseTables.certificateLayouts,
        {
          'id': 'layout-${widget.projectId}',
          'project_id': widget.projectId,
          'canvas_width': _canvasWidth,
          'canvas_height': _canvasHeight,
          'grid_enabled': 1,
          'settings_json': jsonEncode({'updated_by': 'designer', 'zoom': _zoom}),
          'updated_at': now,
        },
        conflictColumn: 'project_id',
      );
    } finally {
      await widget.database.endBatch();
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveLabel = 'Saved just now';
    });
  }

  void _moveField(String id, Offset delta) {
    final field = _fields.firstWhere((item) => item.id == id);
    final next = field.copyWith(
      x: (field.x + delta.dx / _zoom)
          .clamp(0, _canvasWidth - field.width)
          .toDouble(),
      y: (field.y + delta.dy / _zoom)
          .clamp(0, _canvasHeight - field.height)
          .toDouble(),
    );
    _replaceField(next);
  }

  void _resizeField(
    String id,
    Offset delta, {
    required bool fromLeft,
    required bool fromTop,
  }) {
    final field = _fields.firstWhere((item) => item.id == id);
    final dx = delta.dx / _zoom;
    final dy = delta.dy / _zoom;
    if (field.qr) {
      final horizontalDelta = fromLeft ? -dx : dx;
      final verticalDelta = fromTop ? -dy : dy;
      final sizeDelta = horizontalDelta.abs() >= verticalDelta.abs()
          ? horizontalDelta
          : verticalDelta;
      final size = (field.width + sizeDelta)
          .clamp(40, math.min(_canvasWidth - field.x, _canvasHeight - field.y))
          .toDouble();
      final x = fromLeft ? field.x + field.width - size : field.x;
      final y = fromTop ? field.y + field.height - size : field.y;
      _replaceField(field.copyWith(x: x, y: y, width: size, height: size));
      return;
    }
    var x = field.x;
    var y = field.y;
    var width = field.width;
    var height = field.height;
    if (fromLeft) {
      final nextX = (x + dx).clamp(0, x + width - 100).toDouble();
      width -= nextX - x;
      x = nextX;
    } else {
      width = (width + dx).clamp(100, _canvasWidth - x).toDouble();
    }
    if (fromTop) {
      final nextY = (y + dy).clamp(0, y + height - 40).toDouble();
      height -= nextY - y;
      y = nextY;
    } else {
      height = (height + dy).clamp(40, _canvasHeight - y).toDouble();
    }
    _replaceField(field.copyWith(x: x, y: y, width: width, height: height));
  }

  void _replaceField(_DesignerField field) {
    _updateFields(
      _fields.map((item) => item.id == field.id ? field : item).toList(),
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
    if (_undoStack.length <= 1) return;
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
      _saveLabel = 'Unsaved changes';
    });
  }

  bool _sameFields(List<_DesignerField> left, List<_DesignerField> right) =>
      left.length == right.length &&
      left.asMap().entries.every((entry) => entry.value == right[entry.key]);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Design · ${widget.projectName}'),
        actions: [
          Text(_saveLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () =>
                setState(() => _zoom = (_zoom - .1).clamp(.4, 2.2)),
            icon: const Icon(Icons.remove),
          ),
          Text(
            '${(_zoom * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () =>
                setState(() => _zoom = (_zoom + .1).clamp(.4, 2.2)),
            icon: const Icon(Icons.add),
          ),
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
              onAddQr: _addQrField,
              onSelect: (id) => setState(() => _selectedId = id),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _template == null
                  ? const Center(
                      child: Text(
                        'Select a template before designing this certificate.',
                      ),
                    )
                  : _Canvas(
                      fields: _fields,
                      selectedId: _selectedId,
                      previewData: _previewData,
                      templatePath: _templatePath,
                      canvasWidth: _canvasWidth,
                      canvasHeight: _canvasHeight,
                      zoom: _zoom,
                      fontFamilies: _fontFamilies,
                      onSelect: (id) => setState(() => _selectedId = id),
                      onMove: _moveField,
                      onResize: _resizeField,
                    ),
            ),
          ),
          SizedBox(
            width: 300,
            child: _PropertiesPanel(
              field: _selected,
              columns: _columns,
              fontFamilies: _fontFamilies,
              onChanged: _replaceField,
              onDelete: _deleteSelected,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _decodeMap(Object? raw) => raw is String && raw.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(raw) as Map) : <String, dynamic>{};
  double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
}

class _ElementsPanel extends StatelessWidget {
  const _ElementsPanel({
    required this.columns,
    required this.fields,
    required this.selectedId,
    required this.onAdd,
    required this.onAddQr,
    required this.onSelect,
  });
  final List<String> columns;
  final List<_DesignerField> fields;
  final String? selectedId;
  final VoidCallback onAdd;
  final VoidCallback onAddQr;
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
            onPressed: columns.isEmpty ? null : onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Data field'),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddQr,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('QR code'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Layers', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        if (fields.isEmpty)
          const Text('Add a field from imported data to start designing.'),
        Expanded(
          child: ListView(
            children: [
              for (final field in fields)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    selected: field.id == selectedId,
                    dense: true,
                    leading: Icon(field.qr ? Icons.qr_code_2 : Icons.text_fields, size: 18),
                    title: Text(field.qr ? 'Verification QR' : field.source),
                    subtitle: Text(
                      '${field.width.round()} × ${field.height.round()}',
                    ),
                    onTap: () => onSelect(field.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.fields,
    required this.selectedId,
    required this.previewData,
    required this.templatePath,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.zoom,
    required this.fontFamilies,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });
  final List<_DesignerField> fields;
  final String? selectedId;
  final Map<String, dynamic> previewData;
  final String templatePath;
  final double canvasWidth;
  final double canvasHeight;
  final double zoom;
  final List<String> fontFamilies;
  final ValueChanged<String> onSelect;
  final void Function(String, Offset) onMove;
  final void Function(
    String,
    Offset, {
    required bool fromLeft,
    required bool fromTop,
  })
  onResize;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    constrained: false,
    minScale: .4,
    maxScale: 2.2,
    boundaryMargin: const EdgeInsets.all(160),
    child: Transform.scale(
      scale: zoom,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: templateFileExists(templatePath)
                  ? templateCanvasPreview(templatePath)
                  : Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text('Template image unavailable'),
                      ),
                    ),
            ),
            for (final field in fields)
              _CanvasField(
                field: field,
                selected: field.id == selectedId,
                previewText: field.qr ? 'QR' : '${previewData[field.source] ?? field.source}',
                fontFamilies: fontFamilies,
                onSelect: () => onSelect(field.id),
                onMove: (delta) => onMove(field.id, delta),
                onResize: (delta, fromLeft, fromTop) => onResize(
                  field.id,
                  delta,
                  fromLeft: fromLeft,
                  fromTop: fromTop,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CanvasField extends StatelessWidget {
  const _CanvasField({
    required this.field,
    required this.selected,
    required this.previewText,
    required this.fontFamilies,
    required this.onSelect,
    required this.onMove,
    required this.onResize,
  });
  final _DesignerField field;
  final bool selected;
  final String previewText;
  final List<String> fontFamilies;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;
  final void Function(Offset, bool, bool) onResize;
  @override
  Widget build(BuildContext context) => Positioned(
    left: field.x,
    top: field.y,
    width: field.width,
    height: field.height,
    child: GestureDetector(
      onTap: onSelect,
      onPanStart: (_) => onSelect(),
      onPanUpdate: (details) => onMove(details.delta),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: field.textAlignment,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryLight.withValues(alpha: .45)
                  : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: field.qr
                ? const Center(child: Icon(Icons.qr_code_2, size: 96))
                : Text(
                    previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: field.textDirection,
                    style: TextStyle(
                      fontFamily: field.fontFamily,
                      // Keep the chosen family first, then let Flutter use a
                      // platform Arabic font for missing glyphs. This does not
                      // alter layout constraints or the user's font choice.
                      fontFamilyFallback: [
                        ...fontFamilies.where(
                          (family) => family != field.fontFamily,
                        ),
                        'Noto Naskh Arabic',
                        'Noto Sans Arabic',
                        'Arial',
                      ],
                      fontSize: field.fontSize,
                      color: _hex(field.color),
                      fontWeight: field.bold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: field.italic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
          ),
          if (selected) ...[
            _ResizeHandle(
              alignment: Alignment.topLeft,
              onDrag: (delta) => onResize(delta, true, true),
            ),
            _ResizeHandle(
              alignment: Alignment.topRight,
              onDrag: (delta) => onResize(delta, false, true),
            ),
            _ResizeHandle(
              alignment: Alignment.bottomLeft,
              onDrag: (delta) => onResize(delta, true, false),
            ),
            _ResizeHandle(
              alignment: Alignment.bottomRight,
              onDrag: (delta) => onResize(delta, false, false),
            ),
          ],
        ],
      ),
    ),
  );
  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFF20332B);
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.alignment, required this.onDrag});
  final Alignment alignment;
  final ValueChanged<Offset> onDrag;
  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 2),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({
    required this.field,
    required this.columns,
    required this.fontFamilies,
    required this.onChanged,
    required this.onDelete,
  });
  final _DesignerField? field;
  final List<String> columns;
  final List<String> fontFamilies;
  final ValueChanged<_DesignerField> onChanged;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final selected = field;
    if (selected == null) {
      return const Center(
        child: Text('Select a field to edit its properties.'),
      );
    }
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
          if (!selected.qr)
            DropdownButtonFormField<String>(
              initialValue: columns.contains(selected.source) ? selected.source : null,
              decoration: const InputDecoration(labelText: 'Data source field'),
              items: [
                for (final column in columns)
                  DropdownMenuItem(value: column, child: Text(column)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(selected.copyWith(
                    source: value,
                    className: canonicalFieldClassId(value),
                  ));
                }
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Position and size',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-x'),
                  label: 'X',
                  value: selected.x,
                  onChanged: (value) => onChanged(selected.copyWith(x: value)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-y'),
                  label: 'Y',
                  value: selected.y,
                  onChanged: (value) => onChanged(selected.copyWith(y: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-width'),
                  label: 'Width',
                  value: selected.width,
                  onChanged: (value) => onChanged(
                    selected.copyWith(
                      width: value,
                      height: selected.qr ? value : selected.height,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberInput(
                  key: ValueKey('${selected.id}-height'),
                  label: 'Height',
                  value: selected.height,
                  onChanged: (value) => onChanged(
                    selected.copyWith(
                      width: selected.qr ? value : selected.width,
                      height: value,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!selected.qr) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selected.fontFamily,
            decoration: const InputDecoration(labelText: 'Font family'),
            isExpanded: true,
            items: [
              for (final family in fontFamilies)
                DropdownMenuItem(value: family, child: Text(family)),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(selected.copyWith(fontFamily: value));
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _NumberInput(
            key: ValueKey('${selected.id}-font-size'),
            label: 'Font size',
            value: selected.fontSize,
            onChanged: (value) =>
                onChanged(selected.copyWith(fontSize: value.clamp(8, 180))),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selected.alignment,
            decoration: const InputDecoration(labelText: 'Text alignment'),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(selected.copyWith(alignment: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: selected.direction,
            decoration: const InputDecoration(labelText: 'Text direction'),
            items: const [
              DropdownMenuItem(value: 'ltr', child: Text('LTR')),
              DropdownMenuItem(value: 'rtl', child: Text('RTL')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(selected.copyWith(direction: value));
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bold'),
              value: selected.bold,
              onChanged: (value) => onChanged(selected.copyWith(bold: value)),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Italic'),
              value: selected.italic,
              onChanged: (value) => onChanged(selected.copyWith(italic: value)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: selected.color,
            decoration: const InputDecoration(
              labelText: 'Text color (#RRGGBB)',
            ),
            onChanged: (value) {
              if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
                onChanged(selected.copyWith(color: value));
              }
            },
          ),
          ],
          const SizedBox(height: AppSpacing.md),
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

class _NumberInput extends StatefulWidget {
  const _NumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _controller = TextEditingController(
    text: _formatValue(widget.value),
  );
  late final FocusNode _focusNode = FocusNode();
  double? _pendingValue;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  static String _formatValue(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toString();

  void _commit() {
    final value = _pendingValue ?? double.tryParse(_controller.text.trim());
    if (value == null) {
      _controller.value = TextEditingValue(
        text: _formatValue(widget.value),
        selection: TextSelection.collapsed(offset: _formatValue(widget.value).length),
      );
      return;
    }
    _pendingValue = null;
    widget.onChanged(value);
    final text = _formatValue(value);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent rebuilds after every valid keystroke. Never replace the
    // controller text while the user is editing, otherwise deleting a value
    // or inserting a digit moves the caret and restores the previous value.
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      final text = _formatValue(widget.value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focusNode,
    decoration: InputDecoration(labelText: widget.label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.done,
    onChanged: (text) {
      _pendingValue = double.tryParse(text.trim());
    },
    onEditingComplete: _commit,
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
              'Import recipient data first so fields can be mapped to columns.',
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
    this.direction = 'ltr',
    this.fontFamily = 'Cairo',
    this.bold = false,
    this.italic = false,
    this.qr = false,
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
  final String direction;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final bool qr;
  Alignment get textAlignment => switch (alignment) {
    'center' => Alignment.center,
    'right' => Alignment.centerRight,
    _ => Alignment.centerLeft,
  };
  TextDirection get textDirection =>
      direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr;

  factory _DesignerField.fromRow(Map<String, Object?> row) {
    final position = _decode(row['position_json']);
    final style = _decode(row['style_json']);
    return _DesignerField(
      id: row['id']! as String,
      className: canonicalFieldClassId(row['class_name']! as String),
      source: (row['source'] as String?) ?? '',
      x: _number(position['x'], 100),
      y: _number(position['y'], 100),
      width: _number(position['width'], 420),
      height: _number(position['height'], 64),
      fontSize: _number(style['font_size'], 28),
      color: (style['color'] as String?) ?? '#20332B',
      alignment: (style['alignment'] as String?) ?? 'left',
      direction: (style['direction'] as String?) ?? 'ltr',
      fontFamily: (style['font_family'] as String?) ?? 'Cairo',
      bold: style['bold'] == true || style['font_weight'] == 'bold',
      italic: style['italic'] == true,
      qr: style['kind'] == 'qr',
    );
  }
  Map<String, Object?> toRow(String projectId, String now) => {
    'id': id,
    'project_id': projectId,
    'class_name': canonicalFieldClassId(className),
    'source': source,
    'position_json': jsonEncode({
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    }),
      'style_json': jsonEncode({
      'kind': qr ? 'qr' : 'text',
      'font_size': fontSize,
      'color': color,
      'alignment': alignment,
      'direction': direction,
      'font_family': fontFamily,
      'font_weight': bold ? 'bold' : 'normal',
      'bold': bold,
      'italic': italic,
    }),
    'created_at': now,
    'updated_at': now,
  };
  _DesignerField copyWith({
    String? className,
    String? source,
    double? x,
    double? y,
    double? width,
    double? height,
    double? fontSize,
    String? color,
    String? alignment,
    String? direction,
    String? fontFamily,
    bool? bold,
    bool? italic,
    bool? qr,
  }) => _DesignerField(
    id: id,
    className: className ?? this.className,
    source: source ?? this.source,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    alignment: alignment ?? this.alignment,
    direction: direction ?? this.direction,
    fontFamily: fontFamily ?? this.fontFamily,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    qr: qr ?? this.qr,
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
