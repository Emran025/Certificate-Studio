import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/font_repository_impl.dart';
import '../../domain/entities/font_asset.dart';
import '../bloc/fonts_library_bloc.dart';

class FontsLibraryScreen extends StatefulWidget {
  const FontsLibraryScreen({super.key, required this.database, this.projectId});
  final AppDatabase database;
  final String? projectId;
  @override
  State<FontsLibraryScreen> createState() => _FontsLibraryScreenState();
}

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
        FontsLibraryBloc(FontRepositoryImpl(widget.database), widget.projectId)
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

class _FontCard extends StatelessWidget {
  const _FontCard({
    required this.font,
    required this.previewText,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.selected,
    required this.compact,
    required this.onUse,
    required this.onDelete,
  });

  final FontAsset font;
  final String previewText;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool selected;
  final bool compact;
  final VoidCallback? onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final previewStyle = TextStyle(
      fontFamily: font.family,
      fontSize: compact ? 16 : 22,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
    );
    final actions = <Widget>[
      if (onUse != null)
        TextButton(
          onPressed: selected ? null : onUse,
          child: Text(
            selected ? context.l10n.text('In use') : context.l10n.text('Use'),
          ),
        ),
      IconButton(
        tooltip: context.l10n.text('Delete'),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ];

    return AppSurfaceCard(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.text_fields, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        font.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: previewStyle,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.l10n.text(
                    '${font.family} · ${font.format.toUpperCase()}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.text_fields)),
                title: Text(font.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previewText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: previewStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.text(
                        '${font.family} · ${font.format.toUpperCase()}\n${font.filePath}',
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
            ),
    );
  }
}

class _FontPreviewEditor extends StatelessWidget {
  const _FontPreviewEditor({
    required this.controller,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onUnderlineChanged,
  });

  final TextEditingController controller;
  final bool bold;
  final bool italic;
  final bool underline;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<bool> onUnderlineChanged;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('Live font preview'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.text(
              'Write a sample to compare how every imported font renders it.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.text('Preview text'),
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              FilterChip(
                label: const Text('B'),
                selected: bold,
                onSelected: onBoldChanged,
              ),
              FilterChip(
                label: const Text('I'),
                selected: italic,
                onSelected: onItalicChanged,
              ),
              FilterChip(
                label: const Text('U'),
                selected: underline,
                onSelected: onUnderlineChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
