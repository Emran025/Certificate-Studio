import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/database/database_tables.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/features/institution/data/repositories/institution_repository_impl.dart';
import 'package:certificate_studio/features/institution/presentation/screens/institution_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders institution setup when no institution exists', (tester) async {
    final database = InMemoryAppDatabase();
    await database.open();

    await tester.pumpWidget(TestInstitutionSetup(
      repository: InstitutionRepositoryImpl(database),
      keyManager: InstitutionKeyManager(InMemoryKeyStorage()),
    ));

    expect(find.text('Set up your institution'), findsOneWidget);
    expect(find.text('Institution name *'), findsOneWidget);
  });

  testWidgets('saves institution details and initializes a key', (tester) async {
    final database = InMemoryAppDatabase();
    await database.open();
    final storage = InMemoryKeyStorage();

    await tester.pumpWidget(TestInstitutionSetup(
      repository: InstitutionRepositoryImpl(database),
      keyManager: InstitutionKeyManager(storage),
    ));
    await tester.enterText(find.byType(TextFormField).first, 'Al-Noor Academy');
    final button = find.text('Continue to workspace');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(await database.query(DatabaseTables.institutions), hasLength(1));
    expect(await InstitutionKeyManager(storage).hasKey(), isTrue);
  });
}

class TestInstitutionSetup extends StatelessWidget {
  const TestInstitutionSetup({super.key, required this.repository, required this.keyManager});

  final InstitutionRepositoryImpl repository;
  final InstitutionKeyManager keyManager;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: InstitutionSetupScreen(repository: repository, keyManager: keyManager, onCompleted: (_) {}),
      );
}
