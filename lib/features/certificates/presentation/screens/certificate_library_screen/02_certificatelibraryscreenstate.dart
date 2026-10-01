part of '../certificate_library_screen.dart';

class _CertificateLibraryScreenState extends State<CertificateLibraryScreen> {
  late final CertificateLibraryBloc _certificatesBloc;
  late final CertificateExportServiceContract _exporter;
  String _query = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _exporter = CertificateExportService(database: widget.database);
    _certificatesBloc = CertificateLibraryBloc(
      GetCertificates(CertificateRepositoryImpl(CertificateDataSourceImpl(widget.database))),
      widget.projectId,
    )..add(const CertificatesRequested());
  }

  @override
  void dispose() {
    _certificatesBloc.close();
    super.dispose();
  }

  // void _refresh() => _certificatesBloc.add(const CertificatesRequested());

  Future<void> _verify(_LibraryCertificate certificate) async {
    final result = await CertificateVerificationService(
      widget.database,
      widget.keyStorage,
    ).verify(certificate.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: Row(
          children: [
            Icon(
              result.isValid ? Icons.verified : Icons.error_outline,
              color: result.isValid
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              result.isValid
                  ? 'Certificate is authentic'
                  : 'Verification failed',
            ),
          ],
        ),
        icon: result.isValid ? Icons.verified : Icons.error_outline,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.text('Close')),
          ),
        ],
        child: Text(
          result.isValid
              ? 'The signature and document hash are valid.${result.recordClass == null ? '' : '\nRecipient: ${result.recordClass}'}${result.course == null ? '' : '\nCourse: ${result.course}'}'
              : (result.reason ?? 'The certificate could not be verified.'),
        ),
      ),
    );
  }

  Future<void> _exportSingle(
    _LibraryCertificate certificate,
    String extension,
  ) async {
    final field = await _chooseFileNameField([certificate]);
    if (field == null) return;
    String? path;
    Object? error;
    try {
      path = await _exporter.exportSingle(
        certificate: _exportRow(certificate),
        extension: extension,
        fileName: _fileName(certificate, field),
      );
    } catch (exception) {
      error = exception;
    }
    if (!mounted) return;
    _showExportResult(
      error != null
          ? 'Export failed: $error'
          : path == null
          ? 'The requested file is unavailable.'
          : 'Certificate exported successfully.',
    );
  }

  Future<void> _exportSelected(List<_LibraryCertificate> certificates) async {
    final chosen = certificates
        .where((item) => _selected.contains(item.id))
        .toList();
    if (chosen.isEmpty) return;
    final options = await _chooseExportOptions(chosen);
    if (options == null) return;
    String? path;
    Object? error;
    try {
      path = await _exporter.exportZip(
        certificates: [for (final item in chosen) _exportRow(item)],
        extensions: options.extensions,
        style: options.style,
        fileName: await _projectFileName(chosen),
        fileNameFor: (row) {
          final certificate = chosen.firstWhere(
            (item) => item.id == row['id'],
            orElse: () => chosen.first,
          );
          return _fileName(certificate, options.field);
        },
      );
    } catch (exception) {
      error = exception;
    }
    if (!mounted) return;
    _showExportResult(
      error != null
          ? 'Export failed: $error'
          : path == null
          ? 'No generated files were available to export.'
          : '${chosen.length} certificates exported as a ZIP archive.',
    );
  }

  Future<void> _exportAll(List<_LibraryCertificate> certificates) async {
    final options = await _chooseExportOptions(certificates);
    if (options == null) return;
    String? path;
    Object? error;
    try {
      path = await _exporter.exportZip(
        certificates: [for (final item in certificates) _exportRow(item)],
        extensions: options.extensions,
        style: options.style,
        fileName: await _projectFileName(certificates),
        fileNameFor: (row) {
          final certificate = certificates.firstWhere(
            (item) => item.id == row['id'],
            orElse: () => certificates.first,
          );
          return _fileName(certificate, options.field);
        },
      );
    } catch (exception) {
      error = exception;
    }
    if (!mounted) return;
    _showExportResult(
      error != null
          ? 'Export failed: $error'
          : path == null
          ? 'No generated files were available to export.'
          : '${certificates.length} certificates exported as a ZIP archive.',
    );
  }

  void _showExportResult(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<String?> _chooseFileNameField(
    List<_LibraryCertificate> certificates,
  ) async {
    final fields = <String>{};
    for (final certificate in certificates) {
      fields.addAll(certificate.data.keys);
    }
    if (fields.isEmpty) fields.add('certificate_id');
    final sortedFields = fields.toList()..sort();
    var selected = sortedFields.first;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: Text(context.l10n.text('Choose file name field')),
          icon: Icons.file_present_outlined,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.text('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(context.l10n.text('Export')),
            ),
          ],
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            items: [
              for (final field in sortedFields)
                DropdownMenuItem(value: field, child: Text(field)),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => selected = value);
            },
          ),
        ),
      ),
    );
  }

  Future<_CertificateExportOptions?> _chooseExportOptions(
    List<_LibraryCertificate> certificates,
  ) async {
    final fields = <String>{};
    for (final certificate in certificates) {
      fields.addAll(certificate.data.keys);
    }
    if (fields.isEmpty) fields.add('certificate_id');
    final sortedFields = fields.toList()..sort();
    var field = sortedFields.first;
    final extensions = <String>{'pdf'};
    var style = CertificateExportBundleStyle.flat;
    return showDialog<_CertificateExportOptions>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: Text(context.l10n.text('Certificate export settings')),
          icon: Icons.archive_outlined,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.text('Cancel')),
            ),
            FilledButton(
              onPressed: extensions.isEmpty
                  ? null
                  : () => Navigator.pop(
                      context,
                      _CertificateExportOptions(
                        field: field,
                        extensions: extensions,
                        style: style,
                      ),
                    ),
              child: Text(context.l10n.text('Export')),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: field,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.text('Field used for the file name'),
                ),
                items: [
                  for (final value in sortedFields)
                    DropdownMenuItem(value: value, child: Text(value)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => field = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.text('PDF')),
                value: extensions.contains('pdf'),
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    extensions.add('pdf');
                  } else {
                    extensions.remove('pdf');
                  }
                }),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.text('PNG')),
                value: extensions.contains('png'),
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    extensions.add('png');
                  } else {
                    extensions.remove('png');
                  }
                }),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.text('JPEG')),
                value: extensions.contains('jpg'),
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    extensions.add('jpg');
                  } else {
                    extensions.remove('jpg');
                  }
                }),
              ),
              DropdownButtonFormField<CertificateExportBundleStyle>(
                initialValue: style,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.text('Archive style'),
                ),
                items: [
                  DropdownMenuItem(
                    value: CertificateExportBundleStyle.flat,
                    child: Text(context.l10n.text('All files in one ZIP')),
                  ),
                  DropdownMenuItem(
                    value: CertificateExportBundleStyle.perCertificate,
                    child: Text(
                      context.l10n.text(
                        'ZIP per certificate with signature.txt',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => style = value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _projectFileName(
    List<_LibraryCertificate> certificates,
  ) async {
    final projectId = certificates.first.projectId;
    if (projectId is String) {
      final rows = await widget.database.query(
        DatabaseTables.projects,
        where: {'id': projectId},
        columns: ['name'],
      );
      if (rows.isNotEmpty && rows.first['name'] is String) {
        return _sanitizeFilePart(rows.first['name']! as String);
      }
    }
    return 'project';
  }

  String _fileName(_LibraryCertificate certificate, [String? field]) {
    final id = _sanitizeFilePart(certificate.id);
    final selected = field == null || field == 'certificate_id'
        ? id
        : (certificate.valueFor(field) ?? '');
    final value = selected.trim().isEmpty ? certificate.recipient : selected;
    final recipient = _sanitizeFilePart(value);
    if (field == 'certificate_id') return id;
    return recipient.isEmpty ? id : recipient;
  }

  String _sanitizeFilePart(String value) => value
      .trim()
      .replaceAll(RegExp(r'\s+', unicode: true), '_')
      // Preserve Arabic and every other Unicode letter/digit. Only characters
      // unsafe for a portable filename are replaced.
      .replaceAll(RegExp(r'[^\p{L}\p{N}_-]', unicode: true), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<CertificateLibraryBloc, CertificateLibraryState>(
      bloc: _certificatesBloc,
      builder: (context, state) {
        if (state.status == CertificateLibraryStatus.loading ||
            state.status == CertificateLibraryStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == CertificateLibraryStatus.failure) {
          return Center(
            child: Text(
              context.l10n.text(
                'Unable to load certificates: ${state.errorMessage}',
              ),
            ),
          );
        }
        final all = state.certificates;
        final certificates = all
            .where(
              (certificate) =>
                  certificate.searchText.contains(_query.trim().toLowerCase()),
            )
            .toList();
        return AppPageTable(
          header: AppPageHeader(
            title: context.l10n.text('Generated certificates'),
            subtitle: context.l10n.text(
              context.l10n.text(
                'Browse, preview, verify, and export the actual generated certificate files.',
              ),
            ),
            icon: Icons.workspace_premium_outlined,
            actions: [
              if (all.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (_) => _exportAll(all),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'png',
                      child: Text(
                        context.l10n.text('Export all PNG files (ZIP)'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Text(
                        context.l10n.text('Export all PDF files (ZIP)'),
                      ),
                    ),
                  ],
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.upload_file),
                    label: Text(context.l10n.text('Export all')),
                  ),
                ),
              if (widget.projectId != null)
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: context.l10n.text(
                      'Search by recipient, certificate ID, or project',
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(context.l10n.text('${_selected.length} selected')),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => _exportSelected(certificates),
                        icon: const Icon(Icons.image_outlined),
                        label: Text(context.l10n.text('Export PNG ZIP')),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () => _exportSelected(certificates),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(context.l10n.text('Export PDF ZIP')),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: certificates.isEmpty
                      ? AppSurfaceCard(
                          child: Text(
                            _query.isEmpty
                                ? context.l10n.text(
                                    'No certificates generated yet.',
                                  )
                                : context.l10n.text(
                                    'No certificates match your search.',
                                  ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 430,
                                mainAxisExtent: 390,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                              ),
                          itemCount: certificates.length,
                          itemBuilder: (context, index) => _CertificateCard(
                            certificate: certificates[index],
                            selected: _selected.contains(
                              certificates[index].id,
                            ),
                            onSelected: (value) => setState(() {
                              if (value) {
                                _selected.add(certificates[index].id);
                              } else {
                                _selected.remove(certificates[index].id);
                              }
                            }),
                            onOpen: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _CertificatePreviewScreen(
                                  certificate: certificates[index],
                                  database: widget.database,
                                  keyStorage: widget.keyStorage,
                                  exporter: _exporter,
                                  fileName: _fileName(certificates[index]),
                                ),
                              ),
                            ),
                            onVerify: () => _verify(certificates[index]),
                            onExport: (extension) =>
                                _exportSingle(certificates[index], extension),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
