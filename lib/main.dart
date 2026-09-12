import 'package:flutter/material.dart';

import 'config/env/app_environment.dart';
import 'core/database/app_database.dart';
import 'features/app/presentation/screens/app_startup_gate.dart';
import 'shared/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = InMemoryAppDatabase();
  await database.open();
  runApp(CertificateStudioApp(database: database));
}

class CertificateStudioApp extends StatelessWidget {
  const CertificateStudioApp({super.key, this.database});

  final AppDatabase? database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppEnvironment.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale(AppEnvironment.defaultLocale),
      supportedLocales: AppEnvironment.supportedLocales.map(Locale.new).toList(),
      home: database == null ? const _DatabaseUnavailableView() : AppStartupGate(database: database!),
    );
  }
}

class _DatabaseUnavailableView extends StatelessWidget {
  const _DatabaseUnavailableView();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Local workspace is unavailable.')));
}

// Backwards-compatible alias for existing consumers of the starter app.
typedef MyApp = CertificateStudioApp;
