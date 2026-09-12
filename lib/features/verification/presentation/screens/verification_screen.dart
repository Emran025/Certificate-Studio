import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../../shared/themes/app_spacing.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../domain/certificate_verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.database, required this.keyStorage});
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _controller = TextEditingController();
  CertificateVerificationResult? _result;
  bool _checking = false;
  List<String> _recentIds = [];

  @override
  void initState() { super.initState(); _loadRecent(); }
  Future<void> _loadRecent() async { final rows = await widget.database.query(DatabaseTables.certificates); if (mounted) setState(() => _recentIds = rows.reversed.map((row) => row['id']! as String).take(10).toList()); }
  Future<void> _verify([String? id]) async { final value = (id ?? _controller.text).trim(); if (value.isEmpty) return; setState(() { _checking = true; _result = null; _controller.text = value; }); final result = await CertificateVerificationService(widget.database, widget.keyStorage).verify(value); if (mounted) setState(() { _checking = false; _result = result; }); }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Verify certificate')), body: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Verify certificate', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: AppSpacing.xs), Text('Check authenticity offline using the locally stored document hash and issuer signature.', style: Theme.of(context).textTheme.bodyLarge), const SizedBox(height: AppSpacing.xl), AppSurfaceCard(child: Column(children: [TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Certificate ID', hintText: 'certificate-…', prefixIcon: Icon(Icons.badge_outlined)), onSubmitted: (_) => _verify()), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _checking ? null : _verify, icon: _checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified_user_outlined), label: Text(_checking ? 'Verifying…' : 'Verify offline'))])), const SizedBox(height: AppSpacing.lg), if (_result case final result?) _ResultCard(result: result), if (_recentIds.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), Text('Recent certificates', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: AppSpacing.sm), AppSurfaceCard(padding: EdgeInsets.zero, child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _recentIds.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, index) => ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: Text(_recentIds[index]), trailing: const Icon(Icons.chevron_right), onTap: () => _verify(_recentIds[index]))))]]))));
}

class _ResultCard extends StatelessWidget { const _ResultCard({required this.result}); final CertificateVerificationResult result; @override Widget build(BuildContext context) { final color = result.isValid ? Colors.green : Theme.of(context).colorScheme.error; return AppSurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(result.isValid ? Icons.verified : Icons.gpp_bad_outlined, color: color, size: 32), const SizedBox(width: AppSpacing.md), Expanded(child: Text(result.isValid ? 'Certificate is authentic' : 'Certificate verification failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)))]), const SizedBox(height: AppSpacing.md), if (result.isValid) ...[_Info(label: 'Certificate ID', value: result.certificateId ?? ''), _Info(label: 'Student class', value: result.studentClass ?? 'Not provided'), _Info(label: 'Course', value: result.course ?? 'Not provided')] else Text(result.reason ?? 'Unknown verification error', style: TextStyle(color: color))])); } }
class _Info extends StatelessWidget { const _Info({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(children: [SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.labelLarge)), Expanded(child: Text(value))])); }
