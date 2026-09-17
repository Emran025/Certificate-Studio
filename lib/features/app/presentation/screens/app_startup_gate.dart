import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/security/keys/institution_key_manager.dart';
import '../../../institution/data/repositories/institution_repository_impl.dart';
import '../../../institution/presentation/screens/institution_setup_screen.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../widgets/app_shell.dart';
import '../bloc/startup_bloc.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    required this.database,
    required this.keyStorage,
    this.appSettings = const AppSettings(),
    this.onSettingsChanged,
  });

  final AppDatabase database;
  final KeyStorage keyStorage;
  final AppSettings appSettings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final InstitutionRepositoryImpl _repository;
  late final InstitutionKeyManager _keyManager;
  late final StartupBloc _startupBloc;

  @override
  void initState() {
    super.initState();
    _repository = InstitutionRepositoryImpl(widget.database);
    _keyManager = InstitutionKeyManager(widget.keyStorage);
    _startupBloc = StartupBloc(_repository)..add(const StartupRequested());
  }

  @override
  void dispose() {
    _startupBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartupBloc, StartupState>(
      bloc: _startupBloc,
      builder: (context, state) {
        if (state.status == StartupStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == StartupStatus.failure) {
          return Scaffold(
            body: Center(
              child: Text(
                context.l10n.text(
                  'Unable to load institution: ${state.errorMessage}',
                ),
              ),
            ),
          );
        }
        final institution = state.institution;
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
          appSettings: widget.appSettings,
          onSettingsChanged: widget.onSettingsChanged,
        );
      },
    );
  }

  void _reloadInstitution() => _startupBloc.add(const StartupRequested());
}
