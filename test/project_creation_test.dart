import 'package:certificate_studio/core/database/app_database.dart';
import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/core/security/keys/project_key_manager.dart';
import 'package:certificate_studio/features/projects/data/repositories/project_repository_impl.dart';
import 'package:certificate_studio/features/projects/domain/usecases/create_project.dart';
import 'package:certificate_studio/features/projects/presentation/screens/create_project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates and persists a project with a separate project key', () async {
    final database = InMemoryAppDatabase();
    await database.open();
    final storage = InMemoryKeyStorage();
    final keyManager = ProjectKeyManager(storage);
    final useCase = CreateProject(ProjectRepositoryImpl(database), keyManager);

    final project = await useCase(const CreateProjectParams(name: 'Flutter Advanced 2026', institutionId: 'academy-001', courseName: 'Flutter Advanced', projectType: 'training'));

    expect(project.name, 'Flutter Advanced 2026');
    expect(project.settings['project_type'], 'training');
    expect(await keyManager.hasKey(project.id), isTrue);
    expect(await ProjectRepositoryImpl(database).getById(project.id), isNotNull);
  });

  testWidgets('validates project name before saving', (tester) async {
    final database = InMemoryAppDatabase();
    await database.open();
    final useCase = CreateProject(ProjectRepositoryImpl(database), ProjectKeyManager(InMemoryKeyStorage()));

    await tester.pumpWidget(MaterialApp(home: CreateProjectScreen(institutionId: 'academy-001', createProject: useCase)));
    final button = find.text('Continue');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('Project name is required.'), findsOneWidget);
  });
}
