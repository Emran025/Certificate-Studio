import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/files/certificate_artifact_store.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_colors.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../verification/domain/certificate_verification_service.dart';
import '../../domain/certificate_export_service.dart';

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
  late Future<List<_LibraryCertificate>> _certificates;
  final CertificateExportService _exporter = CertificateExportService();
  String _query = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _certificates = _loadCertificates();
  }

  Future<List<_LibraryCertificate>> _loadCertificates() async {
    final rows = await widget.database.query(
      DatabaseTables.certificates,
      where: widget.projectId == null
          ? const {}
          : {'project_id': widget.projectId},
    );
    final result = <_LibraryCertificate>[];
    for (final row in rows.reversed) {
      final students = await widget.database.query(
        DatabaseTables.students,
        where: {'id': row['student_id']},
      );
      result.add(_LibraryCertificate(row, students.firstOrNull));
    }
    return result;
  }

  void _refresh() {
    final certificates = _loadCertificates();
    setState(() {
      _certificates = certificates;
    });
  }

  Future<void> _verify(_LibraryCertificate certificate) async {
    final result = await CertificateVerificationService(
      widget.database,
      widget.keyStorage,
    ).verify(certificate.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isValid ? Icons.verified : Icons.error_outline,
              color: result.isValid
                  ? AppColors.success
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
        content: Text(
          result.isValid
              ? 'The signature and document hash are valid.${result.studentClass == null ? '' : '\nRecipient: ${result.studentClass}'}${result.course == null ? '' : '\nCourse: ${result.course}'}'
              : (result.reason ?? 'The certificate could not be verified.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

  Future<void> _exportSelected(
    List<_LibraryCertificate> certificates,
    String extension,
  ) async {
    final chosen = certificates
        .where((item) => _selected.contains(item.id))
        .toList();
    if (chosen.isEmpty) return;
    final field = await _chooseFileNameField(chosen);
    if (field == null) return;
    String? path;
    Object? error;
    try {
      path = await _exporter.exportZip(
        certificates: [for (final item in chosen) item.row],
        extension: extension,
        fileName: 'certificates-${DateTime.now().millisecondsSinceEpoch}',
        fileNameFor: (row) => _fileName(_LibraryCertificate(row, null), field),
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

  Future<void> _exportAll(
    List<_LibraryCertificate> certificates,
    String extension,
  ) async {
    final field = await _chooseFileNameField(certificates);
    if (field == null) return;
    String? path;
    Object? error;
    try {
      path = await _exporter.exportZip(
        certificates: [for (final item in certificates) item.row],
        extension: extension,
        fileName: 'certificates-${DateTime.now().millisecondsSinceEpoch}',
        fileNameFor: (row) => _fileName(_LibraryCertificate(row, null), field),
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

  void _showExportResult(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<String?> _chooseFileNameField(
    List<_LibraryCertificate> certificates,
  ) async {
    final fields = <String>{};
    const technicalFields = {
      'signature',
      'public_key',
      'document_hash',
      'institution_id',
      'project_id',
      'certificate_id',
    };
    for (final certificate in certificates) {
      fields.addAll(
        certificate.data.keys.where(
          (field) => !technicalFields.contains(field.trim().toLowerCase()),
        ),
      );
    }
    if (fields.isEmpty) fields.add('certificate_id');
    final sortedFields = fields.toList()..sort();
    var selected = sortedFields.first;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose file name field'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Field used for the exported file name',
            ),
            items: [
              for (final field in sortedFields)
                DropdownMenuItem(value: field, child: Text(field)),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => selected = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  String _fileName(_LibraryCertificate certificate, [String? field]) {
    final id = _sanitizeFilePart(certificate.id);
    final selected = field == null || field == 'certificate_id'
        ? id
        : (certificate.valueFor(field) ?? '');
    final value = selected.trim().isEmpty ? certificate.recipient : selected;
    final recipient = _sanitizeFilePart(value);
    if (field == 'certificate_id') return id;
    return recipient.isEmpty ? id : '$recipient-$id';
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
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<_LibraryCertificate>>(
      future: _certificates,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load certificates: ${snapshot.error}'),
          );
        }
        final all = snapshot.data ?? const <_LibraryCertificate>[];
        final certificates = all
            .where(
              (certificate) =>
                  certificate.searchText.contains(_query.trim().toLowerCase()),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generated certificates',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Browse, preview, verify, and export the actual generated certificate files.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      if (all.isNotEmpty)
                        PopupMenuButton<String>(
                          onSelected: (value) => _exportAll(all, value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'png',
                              child: Text('Export all PNG files (ZIP)'),
                            ),
                            PopupMenuItem(
                              value: 'pdf',
                              child: Text('Export all PDF files (ZIP)'),
                            ),
                          ],
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.archive_outlined),
                                SizedBox(width: AppSpacing.xs),
                                Text('Export all'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText:
                          'Search by recipient, certificate ID, or project',
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text('${_selected.length} selected'),
                        const SizedBox(width: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => _exportSelected(certificates, 'png'),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Export PNG ZIP'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () => _exportSelected(certificates, 'pdf'),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Export PDF ZIP'),
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
                                  ? 'No certificates generated yet.'
                                  : 'No certificates match your search.',
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
                  label: certificate.status,
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
                certificate.id,
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
                      label: const Text('View'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Verify',
                    onPressed: onVerify,
                    icon: const Icon(Icons.verified_user_outlined),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onExport,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'png', child: Text('Export PNG')),
                      PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
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
    appBar: AppBar(
      title: Text(
        certificate.recipient.isEmpty
            ? 'Certificate preview'
            : certificate.recipient,
      ),
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
                        ? 'File unavailable.'
                        : 'Certificate exported successfully.',
                  ),
                ),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'png', child: Text('Export PNG')),
            PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
          ],
        ),
      ],
    ),
    body: Row(
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
          width: 300,
          child: _CertificateDetails(
            certificate: certificate,
            database: database,
            keyStorage: keyStorage,
          ),
        ),
      ],
    ),
  );
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
    color: AppColors.surface,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: ListView(
      children: [
        Text(
          'Certificate details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _Detail(
          label: 'Recipient',
          value: certificate.recipient.isEmpty
              ? 'Unavailable'
              : certificate.recipient,
        ),
        _Detail(label: 'Status', value: certificate.status),
        _Detail(label: 'Identifier', value: certificate.id),
        _Detail(
          label: 'PNG',
          value: certificate.imageReference == null
              ? 'Unavailable'
              : 'Available',
        ),
        _Detail(
          label: 'PDF',
          value: certificate.pdfReference == null ? 'Unavailable' : 'Available',
        ),
        const Divider(height: AppSpacing.xl),
        Text('Security', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _Detail(
          label: 'Document hash',
          value: certificate.row['document_hash']?.toString() ?? 'Unavailable',
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await CertificateVerificationService(
              database,
              keyStorage,
            ).verify(certificate.id);
            if (context.mounted) {
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    result.isValid ? 'Valid signature' : 'Verification failed',
                  ),
                  content: Text(
                    result.isValid
                        ? 'The certificate is authentic.'
                        : result.reason ?? 'Unable to verify.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Verify certificate'),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SelectableText(
          value,
          maxLines: 4,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
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

class _LibraryCertificate {
  _LibraryCertificate(this.row, this.student);
  final Map<String, Object?> row;
  final Map<String, Object?>? student;
  String get id => row['id']?.toString() ?? '';
  String get status => row['status']?.toString() ?? 'unknown';
  String? get imageReference => row['image_path'] as String?;
  String? get pdfReference => row['file_path'] as String?;
  Map<String, dynamic> get data {
    final rawStudent = student?['data_json'];
    if (rawStudent is String) {
      final decoded = jsonDecode(rawStudent);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    final rawDocument = row['document_json'];
    if (rawDocument is String) {
      final decoded = jsonDecode(rawDocument);
      final fields = decoded is Map ? decoded['fields'] : null;
      if (fields is Map) return Map<String, dynamic>.from(fields);
    }
    return {};
  }

  String? valueFor(String field) {
    final exact = data[field];
    if (exact != null) return exact.toString();
    final normalized = field.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    for (final entry in data.entries) {
      final key = entry.key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      if (key == normalized && entry.value != null) return entry.value.toString();
    }
    return null;
  }

  String get recipient {
    final raw = student?['data_json'];
    if (raw is! String) return '';
    final data = jsonDecode(raw);
    if (data is! Map) return '';
    for (final value in data.values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  String get searchText =>
      '$id $status ${row['project_id']} $recipient'.toLowerCase();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
