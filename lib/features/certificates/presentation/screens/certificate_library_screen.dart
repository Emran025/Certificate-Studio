import '../../../../config/localization/app_localizations.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../verification/domain/certificate_verification_service.dart';
import '../../data/services/certificate_export_service.dart';
import '../../data/repositories/certificate_repository_impl.dart';
import '../../domain/entities/certificate_record.dart';
import '../../domain/usecases/get_certificates.dart';
import '../bloc/certificate_library_bloc.dart';

class CertificateLibraryScreen extends StatefulWidget {
  const CertificateLibraryScreen({
    super.key,
    required this.database,
    required this.keyStorage,
    this.projectId,
    this.title = 'Certificate library',
  });

  final AppDatabase database;
  final KeyStorage keyStorage;
  final String? projectId;
  final String title;

  @override
  State<CertificateLibraryScreen> createState() =>
      _CertificateLibraryScreenState();
}

class _CertificateLibraryScreenState extends State<CertificateLibraryScreen> {
  late final CertificateLibraryBloc _certificatesBloc;
  late final CertificateExportService _exporter;
  String _query = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _exporter = CertificateExportService(database: widget.database);
    _certificatesBloc = CertificateLibraryBloc(
      GetCertificates(CertificateRepositoryImpl(widget.database)),
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
              ? 'The signature and document hash are valid.${result.studentClass == null ? '' : '\nRecipient: ${result.studentClass}'}${result.course == null ? '' : '\nCourse: ${result.course}'}'
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
        certificate: certificate.row,
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
        certificates: [for (final item in chosen) item.row],
        extensions: options.extensions,
        style: options.style,
        fileName: await _projectFileName(chosen),
        fileNameFor: (row) =>
            _fileName(_LibraryCertificate(row, null), options.field),
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
        certificates: [for (final item in certificates) item.row],
        extensions: options.extensions,
        style: options.style,
        fileName: await _projectFileName(certificates),
        fileNameFor: (row) =>
            _fileName(_LibraryCertificate(row, null), options.field),
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
    final projectId = certificates.first.row['project_id'];
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

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.certificate,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
    required this.onVerify,
    required this.onExport,
  });
  final _LibraryCertificate certificate;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final VoidCallback onVerify;
  final ValueChanged<String> onExport;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _ArtifactImage(
                  reference: certificate.imageReference,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onSelected(value ?? false),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: AppStatusBadge(
                  label: context.l10n.text(certificate.status),
                  color: AppColors.success,
                  backgroundColor: AppColors.successSurface,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certificate.recipient.isEmpty
                    ? 'Recipient unavailable'
                    : certificate.recipient,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                certificate.secondaryLabel.isEmpty
                    ? context.l10n.text('Certificate data unavailable')
                    : certificate.secondaryLabel,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.l10n.text('View')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: context.l10n.text('Verify'),
                    onPressed: onVerify,
                    icon: const Icon(Icons.verified_user_outlined),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onExport,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'png',
                        child: Text(context.l10n.text('Export PNG')),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text(context.l10n.text('Export PDF')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CertificatePreviewScreen extends StatelessWidget {
  const _CertificatePreviewScreen({
    required this.certificate,
    required this.database,
    required this.keyStorage,
    required this.exporter,
    required this.fileName,
  });
  final _LibraryCertificate certificate;
  final AppDatabase database;
  final KeyStorage keyStorage;
  final CertificateExportService exporter;
  final String fileName;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPageTable(
      header: AppPageHeader(
        title: certificate.recipient.isEmpty
            ? context.l10n.text('Certificate preview')
            : certificate.recipient,
        subtitle: context.l10n.text(
          'Preview, verify, and export this generated certificate.',
        ),
        icon: Icons.workspace_premium_outlined,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final path = await exporter.exportSingle(
                certificate: certificate.row,
                extension: value,
                fileName: fileName,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      path == null
                          ? context.l10n.text('File unavailable.')
                          : context.l10n.text(
                              'Certificate exported successfully.',
                            ),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'png',
                child: Text(context.l10n.text('Export PNG')),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Text(context.l10n.text('Export PDF')),
              ),
            ],
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
      child: Row(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: .5,
              maxScale: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _ArtifactImage(
                    reference: certificate.imageReference,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 340,
            child: _CertificateDetails(
              certificate: certificate,
              database: database,
              keyStorage: keyStorage,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CertificateExportOptions {
  const _CertificateExportOptions({
    required this.field,
    required this.extensions,
    required this.style,
  });

  final String field;
  final Set<String> extensions;
  final CertificateExportBundleStyle style;
}

class _CertificateDetails extends StatelessWidget {
  const _CertificateDetails({
    required this.certificate,
    required this.database,
    required this.keyStorage,
  });
  final _LibraryCertificate certificate;
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  Widget build(BuildContext context) => Container(
    color: context.themeBackground,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: ListView(
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.themeSelection,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: context.themePrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.text('Certificate details'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _Detail(
                icon: Icons.person_outline,
                label: context.l10n.text('Recipient'),
                value: certificate.recipient.isEmpty
                    ? context.l10n.text('Unavailable')
                    : certificate.recipient,
              ),
              _Detail(
                icon: Icons.verified_outlined,
                label: context.l10n.text('Status'),
                value: context.l10n.text(certificate.status),
              ),
              _Detail(
                icon: Icons.tag_outlined,
                label: context.l10n.text('Identifier'),
                value: certificate.id,
              ),
              _Detail(
                icon: Icons.image_outlined,
                label: context.l10n.text('PNG'),
                value: certificate.imageReference == null
                    ? context.l10n.text('Unavailable')
                    : context.l10n.text('Available'),
              ),
              _Detail(
                icon: Icons.picture_as_pdf_outlined,
                label: context.l10n.text('PDF'),
                value: certificate.pdfReference == null
                    ? context.l10n.text('Unavailable')
                    : context.l10n.text('Available'),
                showDivider: false,
              ),
            ],
          ),
        ),
        const Divider(height: AppSpacing.xl),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: context.themePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.text('Security'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Detail(
                icon: Icons.fingerprint,
                label: context.l10n.text('Document hash'),
                value:
                    certificate.row['document_hash']?.toString() ??
                    context.l10n.text('Unavailable'),
                showDivider: false,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await CertificateVerificationService(
                      database,
                      keyStorage,
                    ).verify(certificate.id);
                    if (context.mounted) {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AppDialog(
                          title: Text(
                            result.isValid
                                ? context.l10n.text('Valid signature')
                                : context.l10n.text('Verification failed'),
                          ),
                          icon: result.isValid
                              ? Icons.verified
                              : Icons.error_outline,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(context.l10n.text('Close')),
                            ),
                          ],
                          child: Text(
                            result.isValid
                                ? context.l10n.text(
                                    'The certificate is authentic.',
                                  )
                                : result.reason ??
                                      context.l10n.text('Unable to verify.'),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(context.l10n.text('Verify certificate')),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Icon(icon, size: 18, color: context.themePrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.themeMutedText,
                    ),
                  ),
                  SelectableText(
                    value,
                    maxLines: 4,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (showDivider) const Divider(height: 1),
    ],
  );
}

class _ArtifactImage extends StatelessWidget {
  const _ArtifactImage({required this.reference, this.fit = BoxFit.contain});
  final String? reference;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (reference == null) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 42),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: CertificateArtifactStore().read(reference!),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        return bytes == null
            ? const Center(
                child: Icon(Icons.image_not_supported_outlined, size: 42),
              )
            : Image.memory(
                bytes,
                fit: fit,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
              );
      },
    );
  }
}

typedef _LibraryCertificate = CertificateRecord;
