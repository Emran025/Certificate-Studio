import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/data_import_repository_impl.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';
import '../bloc/data_import_bloc.dart';
import '../widgets/data_preview.dart';

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
      saveTable: (table) => repository.saveForProject(widget.projectId, table),
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

  void _import() => _bloc.add(PasteTableRequested(_controller.text));

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DataImportBloc, DataImportState>(
    bloc: _bloc,
    builder: (context, state) {
      final table = state.table;
      final saving = state.isSaving;
      return Scaffold(
        body: state.status == DataImportStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : AppPageTable(
                header: AppPageHeader(
                  title: context.l10n.text('Add student data'),
                  subtitle: context.l10n.text(
                    'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.',
                  ),
                  icon: Icons.table_chart_outlined,
                  actions: [
                    if (table.rowCount > 0)
                      Text(
                        context.l10n.text('${table.rowCount} records saved'),
                      ),
                    IconButton(
                      tooltip: context.l10n.text('Back'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        context.l10n.text('Back') == "Back"
                            ? Icons.arrow_back
                            : Icons.arrow_forward,
                      ),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ImportCard(
                        controller: _controller,
                        saving: saving,
                        onPickExcel: _pickExcelFile,
                        onPaste: _pasteFromClipboard,
                        onImport: _import,
                        errorMessage: state.errorMessage,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (table.columns.isNotEmpty) ...[
                        Text(
                          context.l10n.text('Data preview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DataPreview(
                          table: table,
                          disabled: saving,
                          onChanged: _updateTable,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ] else
                        const _EmptyImportState(),
                    ],
                  ),
                ),
              ),
      );
    },
  );

  void _updateTable(ImportedTable table) =>
      _bloc.add(TableUpdatedRequested(table));
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.controller,
    required this.saving,
    required this.onPickExcel,
    required this.onPaste,
    required this.onImport,
    this.errorMessage,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onPickExcel;
  final VoidCallback onPaste;
  final VoidCallback onImport;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: context.l10n.text('Paste table data'),
            hintText: context.l10n.text('tableDataExample'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppSecondaryButton(
              label: context.l10n.text('Choose Excel file'),
              icon: Icons.table_view_outlined,
              onPressed: saving ? null : onPickExcel,
            ),
            AppSecondaryButton(
              label: context.l10n.text('Paste from clipboard'),
              icon: Icons.content_paste,
              onPressed: saving ? null : onPaste,
            ),
            AppPrimaryButton(
              label: saving
                  ? context.l10n.text('Saving...')
                  : context.l10n.text('Import data'),
              icon: Icons.file_download_outlined,
              onPressed: saving ? null : onImport,
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.text(errorMessage!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.themeError),
          ),
        ],
      ],
    ),
  );
}

class _EmptyImportState extends StatelessWidget {
  const _EmptyImportState();

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Row(
      children: [
        Icon(Icons.info_outline, color: context.themePrimary),
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
  );
}
