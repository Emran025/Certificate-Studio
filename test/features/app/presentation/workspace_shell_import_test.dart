import 'package:certificate_studio/config/localization/app_localizations.dart';
import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/features/app/presentation/widgets/app_shell.dart';
import 'package:certificate_studio/features/institution/domain/entities/institution.dart';
import 'package:certificate_studio/features/settings/data/services/workspace_transfer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home import button calls the project transfer service', (
    tester,
  ) async {
    final database = InMemoryAppDatabase();
    await database.open();
    addTearDown(database.close);
    final now = DateTime.utc(2026);
    final institution = Institution(
      id: 'institution-1',
      institutionId: 'academy-1',
      name: 'Academy',
      createdAt: now,
      updatedAt: now,
    );
    final transferService = _FakeWorkspaceTransferService();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorkspaceShell(
          database: database,
          institution: institution,
          workspaceTransferService: transferService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final importButton = find.text('Import project');
    expect(importButton, findsOneWidget);
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(transferService.importedInstitutionId, institution.id);
    expect(tester.takeException(), isNull);
  });
}

class _FakeWorkspaceTransferService
    implements WorkspaceTransferServiceContract {
  String? importedInstitutionId;

  @override
  Future<String?> importProject(String institutionId) async {
    importedInstitutionId = institutionId;
    return null;
  }

  @override
  Future<String?> exportProfile(String institutionId) async =>
      throw UnimplementedError();

  @override
  Future<bool> importProfile() async => throw UnimplementedError();

  @override
  Future<String?> exportProject(String projectId) async =>
      throw UnimplementedError();
}
