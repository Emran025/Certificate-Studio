part of '../certificate_designer_screen.dart';

class _CertificateDesignerScreenState extends State<CertificateDesignerScreen>
    with WidgetsBindingObserver {
  List<_DesignerField> _fields = [];
  List<String> _columns = [];
  Map<String, dynamic> _previewData = {};
  Map<String, dynamic> _projectSettings = {};
  Map<String, Object?>? _template;
  String? _selectedId;
  bool _loading = true;
  bool _saving = false;
  bool _hasUnsavedChanges = false;
  bool _isPopping = false;
  String _saveLabel = 'Not saved';
  final Set<String> _loadedFontFamilies = {};
  String _projectFontFamily = 'Cairo';
  String? _projectFontId;
  Map<String, String> _fontIdsByFamily = {};
  Map<String, String> _fontFamiliesById = {};
  List<String> _fontFamilies = const ['Cairo', 'Arial', 'sans-serif'];
  double _zoom = 0.55;
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
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _save();
    }
  }

  Future<void> _load() async {
    final rows = await widget.database.query(
      DatabaseTables.certificateFields,
      where: {'project_id': widget.projectId},
    );
    final records = await widget.database.query(
      DatabaseTables.records,
      where: {'project_id': widget.projectId},
    );
    final projects = await widget.database.query(
      DatabaseTables.projects,
      where: {'id': widget.projectId},
    );
    final projectTemplateId = projects.firstOrNull?['template_id'] as String?;
    final projectSettings = _decodeMap(projects.firstOrNull?['settings_json']);
    final layoutSettings = _decodeMap(projectSettings['layout']);
    final savedZoom = _number(
      layoutSettings['zoom'],
      _zoom,
    ).clamp(.4, 2.2).toDouble();
    final projectFontId = projectSettings['font_id']?.toString();
    final projectFonts = projectFontId == null
        ? const <Map<String, Object?>>[]
        : await widget.database.query(
            DatabaseTables.fonts,
            where: {'id': projectFontId},
          );
    final fontRows = await widget.database.query(DatabaseTables.fonts);
    final fontIdsByFamily = <String, String>{};
    final fontFamiliesById = <String, String>{};
    for (final font in fontRows) {
      final id = font['id']?.toString();
      final family = font['family']?.toString().trim();
      if (id == null || id.isEmpty || family == null || family.isEmpty) {
        continue;
      }
      fontIdsByFamily[family] = id;
      fontFamiliesById[id] = family;
    }
    await _registerImportedFonts(fontRows);
    final templates = projectTemplateId == null
        ? <Map<String, Object?>>[]
        : await widget.database.query(
            DatabaseTables.templates,
            where: {'id': projectTemplateId},
          );
    final columns = <String>{};
    Map<String, dynamic> preview = {};
    for (final row in records) {
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
      _projectSettings = projectSettings;
      _projectFontId = projectFontId;
      _fontIdsByFamily = fontIdsByFamily;
      _fontFamiliesById = fontFamiliesById;
      _template = templates.firstOrNull;
      _projectFontFamily =
          projectFonts.firstOrNull?['family']?.toString() ?? 'Cairo';
      _fontFamilies = {
        'Cairo',
        'Arial',
        'sans-serif',
        for (final font in fontRows)
          if (font['family']?.toString().trim().isNotEmpty ?? false)
            font['family']!.toString(),
        _projectFontFamily,
      }.toList();
      _fields = rows.map((row) {
        final field = _DesignerField.fromRow(row);
        return field.copyWith(
          fontFamily: _fontFamiliesById[field.fontId] ?? field.fontFamily,
          fontId:
              field.fontId ??
              _fontIdsByFamily[field.fontFamily] ??
              _projectFontId,
        );
      }).toList();
      _zoom = savedZoom;
      _undoStack
        ..clear()
        ..add(List<_DesignerField>.from(_fields));
      _hasUnsavedChanges = false;
      _loading = false;
    });
  }

  Future<void> _registerImportedFonts(List<Map<String, Object?>> rows) async {
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
      fontId: _projectFontId,
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

  Future<void> _addStaticText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('Static text')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.text('Text')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.text('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.text('Add')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    final id = 'static-${DateTime.now().microsecondsSinceEpoch}';
    final field = _DesignerField(
      id: id,
      className: '__static_text__',
      source: '',
      text: text,
      x: ((_canvasWidth - 420) / 2).clamp(0, _canvasWidth - 120).toDouble(),
      y: (100 + (_fields.length * 70)).clamp(0, _canvasHeight - 64).toDouble(),
      width: 420.clamp(120, _canvasWidth).toDouble(),
      height: 64.clamp(40, _canvasHeight).toDouble(),
      fontSize: 28,
      color: '#20332B',
      fontFamily: _projectFontFamily,
      fontId: _projectFontId,
    );
    await widget.database.insert(
      DatabaseTables.certificateFields,
      field.toRow(widget.projectId, DateTime.now().toUtc().toIso8601String()),
    );
    if (!mounted) return;
    _updateFields([..._fields, field]);
    setState(() => _selectedId = id);
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
    await widget.database.insert(
      DatabaseTables.certificateFields,
      field.toRow(widget.projectId, DateTime.now().toUtc().toIso8601String()),
    );
    if (!mounted) return;
    _updateFields([..._fields, field]);
    setState(() => _selectedId = id);
  }

  Future<void> _save() async {
    if (_saving || !_hasUnsavedChanges) return;
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
      final nextSettings = Map<String, dynamic>.from(_projectSettings)
        ..['layout'] = {
          'canvas_width': _canvasWidth,
          'canvas_height': _canvasHeight,
          'grid_enabled': true,
          'updated_by': 'designer',
          'zoom': _zoom,
        };
      await widget.database.update(DatabaseTables.projects, widget.projectId, {
        'settings_json': jsonEncode(nextSettings),
        'updated_at': now,
      });
      _projectSettings = nextSettings;
    } finally {
      await widget.database.endBatch();
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _hasUnsavedChanges = false;
      _saveLabel = 'Saved just now';
    });
  }

  Future<void> _saveBeforeExit() async {
    if (_isPopping) return;
    _isPopping = true;
    await _save();
    if (mounted) Navigator.of(context).pop();
  }

  void _changeZoom(double value) {
    setState(() {
      _zoom = value.clamp(.4, 2.2).toDouble();
      _hasUnsavedChanges = true;
      _saveLabel = 'Unsaved changes';
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
    field = field.copyWith(fontId: _fontIdsByFamily[field.fontFamily]);
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
      _hasUnsavedChanges = true;
      _saveLabel = 'Unsaved changes';
    });
  }

  void _undo() {
    if (_undoStack.length <= 1) return;
    _redoStack.add(List<_DesignerField>.from(_fields));
    setState(() {
      _fields = List<_DesignerField>.from(_undoStack.removeLast());
      _hasUnsavedChanges = true;
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
      _hasUnsavedChanges = true;
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usePanelDrawers = screenWidth < AppBreakpoints.desktop;
    final compactToolbar = screenWidth < AppBreakpoints.tablet;
    final elementsPanel = _ElementsPanel(
      columns: _columns,
      fields: _fields,
      selectedId: _selectedId,
      onAdd: _addField,
      onAddStaticText: _addStaticText,
      onAddQr: _addQrField,
      onSelect: (id) {
        setState(() => _selectedId = id);
        if (usePanelDrawers) Navigator.of(context).pop();
      },
    );
    final propertiesPanel = _PropertiesPanel(
      field: _selected,
      columns: _columns,
      fontFamilies: _fontFamilies,
      onChanged: _replaceField,
      onDelete: _deleteSelected,
    );
    final canvas = _template == null
        ? const Center(
            child: Text('Select a template before designing this certificate.'),
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
          );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveBeforeExit();
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, control: true):
              _UndoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyY, control: true):
              _RedoIntent(),
          SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
        },
        child: Actions(
          actions: {
            _SaveIntent: CallbackAction<_SaveIntent>(
              onInvoke: (_) {
                _save();
                return null;
              },
            ),
            _UndoIntent: CallbackAction<_UndoIntent>(
              onInvoke: (_) {
                if (_undoStack.length > 1) _undo();
                return null;
              },
            ),
            _RedoIntent: CallbackAction<_RedoIntent>(
              onInvoke: (_) {
                if (_redoStack.isNotEmpty) _redo();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              drawer: usePanelDrawers
                  ? Drawer(
                      width: math.min(320, screenWidth * .86),
                      child: SafeArea(child: elementsPanel),
                    )
                  : null,
              endDrawer: usePanelDrawers
                  ? Drawer(
                      width: math.min(360, screenWidth * .9),
                      child: SafeArea(child: propertiesPanel),
                    )
                  : null,
              body: AppPageTable(
                header: AppPageHeader(
                  title: context.l10n.text('Design · ${widget.projectName}'),
                  subtitle: context.l10n.text(
                    'Place fields on the certificate canvas.',
                  ),
                  icon: Icons.design_services_outlined,
                  actions: [
                    if (usePanelDrawers)
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: context.l10n.text('Elements'),
                          icon: const Icon(Icons.layers_outlined),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    if (!compactToolbar)
                      Text(
                        _saveLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (usePanelDrawers)
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: context.l10n.text('Field properties'),
                          icon: const Icon(Icons.tune),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ),
                    IconButton(
                      tooltip: context.l10n.text('Zoom out'),
                      onPressed: () => _changeZoom(_zoom - .1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '${(_zoom * 100).round()}%',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    IconButton(
                      tooltip: context.l10n.text('Zoom in'),
                      onPressed: () => _changeZoom(_zoom + .1),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: context.l10n.text('back'),
                      onPressed: _saveBeforeExit,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (!usePanelDrawers)
                      SizedBox(width: 230, child: elementsPanel),
                    Expanded(
                      child: Container(
                        color: context.themeBackground,
                        padding: EdgeInsets.all(
                          compactToolbar ? AppSpacing.sm : AppSpacing.lg,
                        ),
                        child: canvas,
                      ),
                    ),
                    if (!usePanelDrawers)
                      SizedBox(width: 300, child: propertiesPanel),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _decodeMap(Object? raw) =>
      raw is String && raw.isNotEmpty
      ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
      : <String, dynamic>{};
  double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
}
