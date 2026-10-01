part of '../settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.database,
    required this.institutionId,
    required this.settings,
    required this.keyStorage,
    this.onSettingsChanged,
  });

  final AppDatabase database;
  final String institutionId;
  final AppSettings settings;
  final KeyStorage keyStorage;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
