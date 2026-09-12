import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../verification/domain/certificate_verification_service.dart';

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
  State<CertificateLibraryScreen> createState() => _CertificateLibraryScreenState();
}

class _CertificateLibraryScreenState extends State<CertificateLibraryScreen> {
  late Future<List<Map<String, Object?>>> _certificates;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _certificates = _loadCertificates();
  }

  Future<List<Map<String, Object?>>> _loadCertificates() async {
    final rows = await widget.database.query(
      DatabaseTables.certificates,
      where: widget.projectId == null ? const {} : {'project_id': widget.projectId},
    );
    return rows.reversed.toList(growable: false);
  }

  void _refresh() => setState(() => _certificates = _loadCertificates());

  Future<void> _verify(String certificateId) async {
    final result = await CertificateVerificationService(widget.database, widget.keyStorage).verify(certificateId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(result.isValid ? Icons.verified : Icons.error_outline, color: result.isValid ? Colors.green : Theme.of(context).colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Text(result.isValid ? 'Certificate is authentic' : 'Verification failed'),
          ],
        ),
        content: Text(result.isValid
            ? 'Certificate ${result.certificateId} is valid${result.studentClass == null ? '' : '\nRecipient: ${result.studentClass}'}${result.course == null ? '' : '\nCourse: ${result.course}'}.'
            : (result.reason ?? 'The certificate could not be verified.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [IconButton(onPressed: _refresh, tooltip: 'Refresh', icon: const Icon(Icons.refresh))],
        ),
        body: FutureBuilder<List<Map<String, Object?>>>(
          future: _certificates,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Unable to load certificates: ${snapshot.error}'));
            final certificates = (snapshot.data ?? const <Map<String, Object?>>[]).where((certificate) {
              final haystack = '${certificate['id']} ${certificate['project_id']} ${certificate['status']}'.toLowerCase();
              return _query.trim().isEmpty || haystack.contains(_query.trim().toLowerCase());
            }).toList();
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generated certificates', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Browse, verify, and manage certificates generated on this device.', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by certificate or project ID'),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: certificates.isEmpty
                            ? AppSurfaceCard(child: Text(_query.isEmpty ? 'No certificates generated yet.' : 'No certificates match your search.'))
                            : AppSurfaceCard(
                                padding: EdgeInsets.zero,
                                child: ListView.separated(
                                  itemCount: certificates.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final certificate = certificates[index];
                                    final id = certificate['id']?.toString() ?? '';
                                    final hash = certificate['document_hash']?.toString() ?? 'not available';
                                    return ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)),
                                      title: Text(id),
                                      subtitle: Text('Project: ${certificate['project_id']}\nStatus: ${certificate['status']} · Hash: ${hash.length > 18 ? '${hash.substring(0, 18)}…' : hash}'),
                                      isThreeLine: true,
                                      trailing: FilledButton.tonalIcon(onPressed: () => _verify(id), icon: const Icon(Icons.verified_user_outlined), label: const Text('Verify')),
                                    );
                                  },
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
