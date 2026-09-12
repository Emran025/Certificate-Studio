import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/certificate_generation_service.dart';

class CertificateGenerationScreen extends StatefulWidget {
  const CertificateGenerationScreen({
    super.key,
    required this.database,
    required this.keyStorage,
    required this.projectId,
    required this.projectName,
    required this.institutionId,
  });
  final AppDatabase database;
  final KeyStorage keyStorage;
  final String projectId;
  final String projectName;
  final String institutionId;
  @override
  State<CertificateGenerationScreen> createState() =>
      _CertificateGenerationScreenState();
}

class _CertificateGenerationScreenState
    extends State<CertificateGenerationScreen> {
  bool _running = false;
  int _completed = 0;
  int _total = 0;
  CertificateGenerationResult? _result;
  List<Map<String, Object?>> _certificates = [];

  Future<void> _generate() async {
    setState(() {
      _running = true;
      _result = null;
      _completed = 0;
    });
    final students = await widget.database.query(
      DatabaseTables.students,
      where: {'project_id': widget.projectId},
    );
    setState(() => _total = students.length);
    final result =
        await CertificateGenerationService(
          widget.database,
          widget.keyStorage,
        ).generate(
          projectId: widget.projectId,
          institutionId: widget.institutionId,
          onProgress: (completed, total) {
            if (mounted)
              setState(() {
                _completed = completed;
                _total = total;
              });
          },
        );
    final certificates = await widget.database.query(
      DatabaseTables.certificates,
      where: {'project_id': widget.projectId},
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
      _certificates = certificates.reversed.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final rows = await widget.database.query(
      DatabaseTables.certificates,
      where: {'project_id': widget.projectId},
    );
    if (mounted) setState(() => _certificates = rows.reversed.toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Generate · ${widget.projectName}')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate certificates',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create signed PDF and high-resolution PNG certificates with offline verification records.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 30),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _running
                                ? 'Generating certificates…'
                                : 'Ready to generate',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (!_running)
                          FilledButton.icon(
                            onPressed: _generate,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Generate'),
                          ),
                      ],
                    ),
                    if (_running) ...[
                      const SizedBox(height: AppSpacing.lg),
                      LinearProgressIndicator(
                        value: _total == 0 ? null : _completed / _total,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('$_completed of $_total recipients processed'),
                    ],
                    if (_result case final result?) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          _Metric(
                            label: 'Generated',
                            value: '${result.generated}',
                          ),
                          _Metric(label: 'Failed', value: '${result.failed}'),
                          _Metric(label: 'Total', value: '${result.total}'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Job ${result.jobId} · ${result.status}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (result.errors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        for (final error in result.errors)
                          Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Certificate library',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_certificates.isEmpty)
                const AppSurfaceCard(
                  child: Text(
                    'No certificates generated yet. Import recipient data, design the layout, then generate.',
                  ),
                )
              else
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _certificates.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final certificate = _certificates[index];
                      return ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: Text(certificate['id']! as String),
                        subtitle: Text(
                          'Status: ${certificate['status']} · Hash: ${(certificate['document_hash'] as String?) ?? 'available'}',
                        ),
                        trailing: const Icon(
                          Icons.verified,
                          color: Colors.green,
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
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    ),
  );
}
