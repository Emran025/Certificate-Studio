part of '../data_import_screen.dart';

class _DataImportScreenState extends State<DataImportScreen> {
  late final DataImportBloc _bloc;
  late final DataImportRepositoryImpl _repository;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = DataImportRepositoryImpl(
      DataImportDataSourceImpl(widget.database),
    );
    _bloc = DataImportBloc(
      projectId: widget.projectId,
      pasteTable: PasteTable(_repository),
      importExcel: ImportExcel(_repository),
      loadTable: () => _repository.getForProject(widget.projectId),
      updateImportedTable: UpdateImportedTable(_repository),
      openExternalLink: OpenExternalLink(const ExternalLinkRepositoryImpl()),
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
    try {
      await _prepareImport(_repository.parseExcel(bytes));
    } on Object catch (error) {
      _bloc.add(DataImportErrorReported(error.toString()));
    }
    _controller.clear();
  }

  Future<void> _import() async {
    try {
      await _prepareImport(_repository.parseTable(_controller.text));
    } on Object catch (error) {
      _bloc.add(DataImportErrorReported(error.toString()));
    }
  }

  Future<void> _prepareImport(ImportedTable incoming) async {
    if (incoming.columns.isEmpty) {
      _bloc.add(
        const DataImportErrorReported(
          'The table does not contain column names.',
        ),
      );
      return;
    }
    if (incoming.rows.isEmpty) {
      _bloc.add(
        const DataImportErrorReported(
          'The table does not contain any recipient rows.',
        ),
      );
      return;
    }
    final existing = await _repository.getForProject(widget.projectId);
    if (!mounted) return;
    final plan = ImportMergePlanner.plan(
      existing: existing,
      incoming: incoming,
    );
    final decisions = await showImportConflictDialog(context, plan);
    if (!mounted || decisions == null) return;
    _bloc.add(
      TableUpdatedRequested(
        plan.apply(
          decisions,
          defaultDecision: ImportMergeDecision.keepExisting,
        ),
      ),
    );
  }

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
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.text(
                          'New rows are appended; existing records are kept. Matching columns are reused and new columns are added.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
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
                          onOpenExternal: (kind, value) => _bloc.add(
                            ExternalLinkRequested(kind: kind, value: value),
                          ),
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
