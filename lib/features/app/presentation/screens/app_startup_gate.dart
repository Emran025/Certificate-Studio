import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../institution/data/repositories/institution_repository_impl.dart';
import '../../../institution/domain/entities/institution.dart';
import '../../../institution/presentation/screens/institution_setup_screen.dart';
import '../widgets/app_shell.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    required this.database,
    required this.keyStorage,
  });

  final AppDatabase database;
  final KeyStorage keyStorage;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final InstitutionRepositoryImpl _repository;
  late final InstitutionKeyManager _keyManager;
  Future<Institution?>? _institutionFuture;

  @override
  void initState() {
    super.initState();
    _repository = InstitutionRepositoryImpl(widget.database);
    _keyManager = InstitutionKeyManager(widget.keyStorage);
    _institutionFuture = _repository.getCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Institution?>(
      future: _institutionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final institution = snapshot.data;
        if (institution == null) {
          return InstitutionSetupScreen(
            repository: _repository,
            keyManager: _keyManager,
            onCompleted: (_) => _reloadInstitution(),
          );
        }
        return WorkspaceShell(
          database: widget.database,
          institution: institution,
          keyStorage: widget.keyStorage,
        );
      },
    );
  }

  Future<void> _reloadInstitution() async {
    final institution = await _repository.getCurrent();
    if (mounted) {
      setState(() {
        _institutionFuture = Future.value(institution);
      });
    }
  }
}
