part of '../data_import_screen.dart';

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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    final file = result.isEmpty ? null : result.first;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
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
                  title: context.l10n.text('Add record data'),
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
