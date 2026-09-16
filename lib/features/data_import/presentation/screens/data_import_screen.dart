import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/data_import_repository_impl.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';
import '../bloc/data_import_bloc.dart';

class DataImportScreen extends StatefulWidget {
  const DataImportScreen({
    super.key,
    required this.database,
    required this.projectId,
  });

  final AppDatabase database;
  final String projectId;

  @override
  State<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends State<DataImportScreen> {
  late final DataImportBloc _bloc;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final repository = DataImportRepositoryImpl(widget.database);
    _bloc = DataImportBloc(
      projectId: widget.projectId,
      pasteTable: PasteTable(repository),
      importExcel: ImportExcel(repository),
      loadTable: () => repository.getForProject(widget.projectId),
    )..add(const DataImportRequested());
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      _bloc.add(
        const DataImportErrorReported(
          'The clipboard does not contain a table.',
        ),
      );
      return;
    }
    _controller.text = text;
    _bloc.add(PasteTableRequested(text));
  }

  Future<void> _import(String rawText) async {
    _bloc.add(PasteTableRequested(rawText));
  }

  Future<void> _pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _bloc.add(
        const DataImportErrorReported(
          'The selected workbook could not be read.',
        ),
      );
      return;
    }
    _bloc.add(ExcelImportRequested(bytes));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataImportBloc, DataImportState>(
      bloc: _bloc,
      builder: (context, state) {
        final table = state.table;
        final saving = state.isSaving;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.text('Student data')),
            actions: [
              if (table.rowCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    child: Text(
                      context.l10n.text('${table.rowCount} records saved'),
                    ),
                  ),
                ),
            ],
          ),
          body: state.status == DataImportStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.text('Add student data'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.l10n.text(
                              'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppSurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _controller,
                                  minLines: 5,
                                  maxLines: 10,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.text(
                                      'Paste table data',
                                    ),
                                    hintText: context.l10n.text(
                                      'tableDataExample',
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    AppSecondaryButton(
                                      label: context.l10n.text(
                                        'Choose Excel file',
                                      ),
                                      icon: Icons.table_view_outlined,
                                      onPressed: saving ? null : _pickExcelFile,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    AppSecondaryButton(
                                      label: context.l10n.text(
                                        'Paste from clipboard',
                                      ),
                                      icon: Icons.content_paste,
                                      onPressed: saving
                                          ? null
                                          : _pasteFromClipboard,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    AppPrimaryButton(
                                      label: saving
                                          ? context.l10n.text('Saving...')
                                          : context.l10n.text('Import data'),
                                      icon: Icons.file_download_outlined,
                                      onPressed: saving
                                          ? null
                                          : () => _import(_controller.text),
                                    ),
                                  ],
                                ),
                                if (state.errorMessage != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    context.l10n.text(state.errorMessage!),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (table.columns.isNotEmpty) ...[
                            Text(
                              context.l10n.text('Data preview'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _DataPreview(table: table),
                            const SizedBox(height: AppSpacing.xl),
                          ] else
                            AppSurfaceCard(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      context.l10n.text(
                                        'No recipient data yet. Import a table to continue to certificate design.',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _DataPreview extends StatelessWidget {
  const _DataPreview({required this.table});
  final ImportedTable table;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: EdgeInsets.zero,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in table.columns) DataColumn(label: Text(column)),
          ],
          rows: [
            for (final row in table.rows.take(50))
              DataRow(
                cells: [
                  for (final column in table.columns)
                    DataCell(Text(row[column] ?? '')),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
