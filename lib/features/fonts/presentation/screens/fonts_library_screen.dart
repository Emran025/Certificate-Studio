import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
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
  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
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
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.text('Fonts'))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _import,
          icon: const Icon(Icons.upload_file),
          label: Text(context.l10n.text('Import font')),
        ),
        body:
            state.status == FontsLibraryStatus.loading ||
                state.status == FontsLibraryStatus.initial
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.text('Font library'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.text('persistedFonts', {
                          'count': state.fonts.length.toString(),
                        }),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.text(
                          'Arabic text keeps its original Unicode characters. If a selected font misses a glyph, the preview and export use the next available fallback font.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
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
                                      const SizedBox(height: AppSpacing.md),
                                      FilledButton.icon(
                                        onPressed: _import,
                                        icon: const Icon(Icons.upload_file),
                                        label: Text(
                                          context.l10n.text('Import font'),
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
                                  return AppSurfaceCard(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const CircleAvatar(
                                          child: Icon(Icons.text_fields),
                                        ),
                                        title: Text(font.name),
                                        subtitle: Text(
                                          context.l10n.text(
                                            '${font.family} · ${font.format.toUpperCase()}\n${font.filePath}',
                                          ),
                                        ),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (widget.projectId != null)
                                              TextButton(
                                                onPressed: selected
                                                    ? null
                                                    : () => context
                                                          .read<
                                                            FontsLibraryBloc
                                                          >()
                                                          .add(
                                                            FontSelected(id),
                                                          ),
                                                child: Text(
                                                  selected
                                                      ? context.l10n.text(
                                                          'In use',
                                                        )
                                                      : context.l10n.text(
                                                          'Use',
                                                        ),
                                                ),
                                              ),
                                            IconButton(
                                              tooltip: context.l10n.text(
                                                'Delete',
                                              ),
                                              onPressed: () => context
                                                  .read<FontsLibraryBloc>()
                                                  .add(FontDeleted(id)),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
