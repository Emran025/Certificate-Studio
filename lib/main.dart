import 'package:flutter/material.dart';

import 'config/env/app_environment.dart';
import 'config/localization/app_localizations.dart';
import 'core/database/app_database.dart';
import 'core/database/persistent_app_database.dart';
import 'core/security/keys/institution_key_manager.dart';
import 'features/app/presentation/screens/app_startup_gate.dart';
import 'shared/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keyStorage = await PersistentKeyStorage.create();
  final database = await PersistentAppDatabase.create(keyStorage: keyStorage);
  runApp(CertificateStudioApp(database: database, keyStorage: keyStorage));
}

class CertificateStudioApp extends StatelessWidget {
  const CertificateStudioApp({super.key, this.database, this.keyStorage});

  final AppDatabase? database;
  final KeyStorage? keyStorage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppEnvironment.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        return supportedLocales.firstWhere(
          (supported) => supported.languageCode == locale.languageCode,
          orElse: () => supportedLocales.first,
        );
      },
      home: database == null
          ? const _DatabaseUnavailableView()
          : AppStartupGate(
              database: database!,
              keyStorage: keyStorage ?? InMemoryKeyStorage(),
            ),
    );
  }
}

class _DatabaseUnavailableView extends StatelessWidget {
  const _DatabaseUnavailableView();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text(context.l10n.text('localWorkspaceUnavailable'))),
      );
}

// Backwards-compatible alias for existing consumers of the starter app.
typedef MyApp = CertificateStudioApp;
