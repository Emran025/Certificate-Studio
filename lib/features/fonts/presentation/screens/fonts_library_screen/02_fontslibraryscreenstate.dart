part of '../fonts_library_screen.dart';

class _FontsLibraryScreenState extends State<FontsLibraryScreen> {
  late final TextEditingController _previewController;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  final Set<String> _loadedFontIds = {};
  final Set<String> _loadingFontIds = {};
  bool _fontLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _previewController = TextEditingController(
      text: 'Certificate Studio — شهادة إتمام',
    )..addListener(_previewChanged);
  }

  @override
  void dispose() {
    _previewController
      ..removeListener(_previewChanged)
      ..dispose();
    super.dispose();
  }

  void _previewChanged() => setState(() {});

  void _scheduleFontLoading(List<FontAsset> fonts) {
    if (_fontLoadScheduled) return;
    _fontLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fontLoadScheduled = false;
      if (mounted) _loadFonts(fonts);
    });
  }

  Future<void> _loadFonts(List<FontAsset> fonts) async {
    for (final font in fonts) {
      if (_loadedFontIds.contains(font.id) || !_loadingFontIds.add(font.id)) {
        continue;
      }
      final rows = await widget.database.query(
        DatabaseTables.fonts,
        where: {'id': font.id},
        columns: ['font_bytes'],
      );
      final raw = rows.firstOrNull?['font_bytes'];
      if (raw is! List<int> || raw.isEmpty) {
        _loadingFontIds.remove(font.id);
        continue;
      }
      try {
        final loader = FontLoader(
          font.family,
        )..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(raw))));
        await loader.load();
        _loadedFontIds.add(font.id);
      } on Object {
        // A font with invalid bytes remains visible using the platform fallback.
      }
      _loadingFontIds.remove(font.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    final file = result.isEmpty ? null : result.first;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    final name = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final format = file.extension?.toLowerCase() ?? 'ttf';
    if (!mounted) return;
    context.read<FontsLibraryBloc>().add(
      FontAdded(
        FontAsset(
          id: 'font-${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          family: name,
          filePath: file.path ?? file.name,
          format: format,
        ),
        bytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        FontsLibraryBloc(FontRepositoryImpl(FontDataSourceImpl(widget.database)), widget.projectId)
          ..add(const FontsRequested()),
    child: BlocBuilder<FontsLibraryBloc, FontsLibraryState>(
      builder: (context, state) {
        if (state.status == FontsLibraryStatus.loaded &&
            state.fonts.isNotEmpty) {
          _scheduleFontLoading(state.fonts);
        }
        return Scaffold(
          body:
              state.status == FontsLibraryStatus.loading ||
                  state.status == FontsLibraryStatus.initial
              ? const Center(child: CircularProgressIndicator())
              : AppPageTable(
                  header: AppPageHeader(
                    title: context.l10n.text('Font library'),
                    subtitle: context.l10n.text(
                      'Manage fonts available to projects.',
                    ),
                    icon: Icons.text_fields_outlined,
                    actions: [
                      FilledButton.icon(
                        onPressed: _import,
                        icon: const Icon(Icons.upload_file),
                        label: Text(context.l10n.text('Import font')),
                      ),
                      if (widget.projectId != null)
                        IconButton(
                          tooltip: context.l10n.text('Back'),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            context.l10n.text('Back') == 'Back'
                                ? Icons.arrow_back
                                : Icons.arrow_forward,
                          ),
                        ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth < AppBreakpoints.tablet;
                      final contentPadding = compact
                          ? const EdgeInsets.all(AppSpacing.sm)
                          : const EdgeInsets.all(AppSpacing.xl);
                      return Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FontPreviewEditor(
                              controller: _previewController,
                              bold: _bold,
                              italic: _italic,
                              underline: _underline,
                              onBoldChanged: (value) =>
                                  setState(() => _bold = value),
                              onItalicChanged: (value) =>
                                  setState(() => _italic = value),
                              onUnderlineChanged: (value) =>
                                  setState(() => _underline = value),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Expanded(
                              child: state.fonts.isEmpty
                                  ? SizedBox(
                                      width: double.infinity,
                                      child: AppSurfaceCard(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.l10n.text(
                                                'No fonts have been imported yet.',
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            FilledButton.icon(
                                              onPressed: _import,
                                              icon: const Icon(
                                                Icons.upload_file,
                                              ),
                                              label: Text(
                                                context.l10n.text(
                                                  'Import font',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: state.fonts.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: AppSpacing.sm),
                                      itemBuilder: (_, index) {
                                        final font = state.fonts[index];
                                        final id = font.id;
                                        final selected = id == state.selectedId;
                                        return _FontCard(
                                          font: font,
                                          previewText: _previewController.text,
                                          bold: _bold,
                                          italic: _italic,
                                          underline: _underline,
                                          selected: selected,
                                          compact: compact,
                                          onUse: widget.projectId == null
                                              ? null
                                              : () => context
                                                    .read<FontsLibraryBloc>()
                                                    .add(FontSelected(id)),
                                          onDelete: () => context
                                              .read<FontsLibraryBloc>()
                                              .add(FontDeleted(id)),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    ),
  );
}
