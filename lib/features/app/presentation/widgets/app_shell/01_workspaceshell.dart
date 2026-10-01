part of '../app_shell.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    this.database,
    this.institution,
    this.keyStorage,
    this.appSettings = const AppSettings(),
    this.onSettingsChanged,
  });

  final AppDatabase? database;
  final Institution? institution;
  final KeyStorage? keyStorage;
  final AppSettings appSettings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}
