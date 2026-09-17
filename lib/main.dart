import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/env/app_environment.dart';
import 'config/localization/app_localizations.dart';
import 'core/database/app_database.dart';
import 'core/database/persistent_app_database.dart';
import 'core/security/keys/institution_key_manager.dart';
import 'features/app/presentation/screens/app_startup_gate.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'shared/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keyStorage = await PersistentKeyStorage.create();
  final database = await PersistentAppDatabase.create(keyStorage: keyStorage);
  final settings = await SettingsRepositoryImpl(database).loadAppSettings();
  runApp(CertificateStudioApp(
    database: database,
    keyStorage: keyStorage,
    initialSettings: settings,
  ));
}

class CertificateStudioApp extends StatefulWidget {
  const CertificateStudioApp({
    super.key,
    this.database,
    this.keyStorage,
    this.initialSettings = const AppSettings(),
  });

  final AppDatabase? database;
  final KeyStorage? keyStorage;
  final AppSettings initialSettings;

  @override
  State<CertificateStudioApp> createState() => _CertificateStudioAppState();
}

class _CertificateStudioAppState extends State<CertificateStudioApp> {
  late AppSettings _settings = widget.initialSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.text(AppEnvironment.appNameKey),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.withAccent(
        brightness: Brightness.light,
        accentColor: _settings.accentColor,
      ),
      darkTheme: AppTheme.withAccent(
        brightness: Brightness.dark,
        accentColor: _settings.accentColor,
      ),
      themeMode: _settings.themeMode == AppThemeMode.dark
          ? ThemeMode.dark
          : _settings.themeMode == AppThemeMode.light
          ? ThemeMode.light
          : ThemeMode.system,
      locale: Locale(_settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        return supportedLocales.firstWhere(
          (supported) => supported.languageCode == locale.languageCode,
          orElse: () => supportedLocales.first,
        );
      },
      home: widget.database == null
          ? const _DatabaseUnavailableView()
          : AppStartupGate(
              database: widget.database!,
              keyStorage: widget.keyStorage ?? InMemoryKeyStorage(),
              appSettings: _settings,
              onSettingsChanged: (settings) => setState(() {
                _settings = settings;
              }),
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
