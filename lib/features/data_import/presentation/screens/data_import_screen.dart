import '../../../../config/localization/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../data/repositories/data_import_repository_impl.dart';
import '../../domain/entities/imported_table.dart';
import '../../domain/usecases/import_excel.dart';
import '../../domain/usecases/paste_table.dart';

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
  late final PasteTable _pasteTable;
  late final ImportExcel _importExcel;
  final _controller = TextEditingController();
  ImportedTable _table = const ImportedTable(columns: [], rows: []);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final repository = DataImportRepositoryImpl(widget.database);
    _pasteTable = PasteTable(repository);
    _importExcel = ImportExcel(repository);
    _load(repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load(DataImportRepositoryImpl repository) async {
    final table = await repository.getForProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _table = table;
      _loading = false;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      setState(() => _error = 'The clipboard does not contain a table.');
      return;
    }
    _controller.text = text;
    await _import(text);
  }

  Future<void> _import(String rawText) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final table = await _pasteTable(
        projectId: widget.projectId,
        rawText: rawText,
      );
      if (mounted) {
        setState(() {
          _table = table;
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'We could not save the imported data. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      setState(() => _error = 'The selected workbook could not be read.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final table = await _importExcel(
        projectId: widget.projectId,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _table = table;
        _controller.clear();
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'We could not import this workbook.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('Student data')),
        actions: [
          if (_table.rowCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(child: Text(context.l10n.text('${_table.rowCount} records saved'))),
            ),
        ],
      ),
      body: _loading
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
                        'Add student data',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.',
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
                                labelText: context.l10n.text('Paste table data'),
                                hintText: 'Field 1\tField 2\tField 3\nValue 1\tValue 2\tValue 3',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                AppSecondaryButton(
                                  label: 'Choose Excel file',
                                  icon: Icons.table_view_outlined,
                                  onPressed: _saving ? null : _pickExcelFile,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppSecondaryButton(
                                  label: 'Paste from clipboard',
                                  icon: Icons.content_paste,
                                  onPressed: _saving
                                      ? null
                                      : _pasteFromClipboard,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppPrimaryButton(
                                  label: _saving ? 'Saving...' : 'Import data',
                                  icon: Icons.file_download_outlined,
                                  onPressed: _saving
                                      ? null
                                      : () => _import(_controller.text),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (_table.columns.isNotEmpty) ...[
                        Text(
                          'Data preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DataPreview(table: _table),
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
                                  'No recipient data yet. Import a table to continue to certificate design.',
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
