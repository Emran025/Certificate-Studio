import 'package:certificate_studio/core/security/keys/institution_key_manager.dart';
import 'package:certificate_studio/core/security/keys/project_key_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstitutionKeyManager', () {
    test('initializes a 32-byte hexadecimal key once', () async {
      final storage = InMemoryKeyStorage();
      final manager = InstitutionKeyManager(storage);

      expect(await manager.hasKey(), isFalse);
      await manager.initialize();
      final first = await storage.read('institution.master_key');
      await manager.initialize();

      expect(await manager.hasKey(), isTrue);
      expect(first, hasLength(64));
      expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await storage.read('institution.master_key'), first);
    });

    test('rotate replaces the existing key', () async {
      final storage = InMemoryKeyStorage();
      final manager = InstitutionKeyManager(storage);
      await manager.initialize();
      final before = await storage.read('institution.master_key');

      await manager.rotate();

      final after = await storage.read('institution.master_key');
      expect(after, hasLength(64));
      expect(after, isNot(before));
    });
  });

  group('ProjectKeyManager', () {
    test('keeps keys isolated by project id', () async {
      final storage = InMemoryKeyStorage();
      final manager = ProjectKeyManager(storage);

      await manager.initialize('project-a');
      await manager.initialize('project-b');

      expect(await manager.hasKey('project-a'), isTrue);
      expect(await manager.hasKey('project-b'), isTrue);
      expect(await manager.hasKey('project-c'), isFalse);
      expect(await storage.read('project.project-a.key'), isNotNull);
      expect(await storage.read('project.project-b.key'), isNotNull);
    });

    test(
      'initialize is idempotent and rotate changes only one project',
      () async {
        final storage = InMemoryKeyStorage();
        final manager = ProjectKeyManager(storage);
        await manager.initialize('project-a');
        await manager.initialize('project-b');
        final aBefore = await storage.read('project.project-a.key');
        final bBefore = await storage.read('project.project-b.key');

        await manager.initialize('project-a');
        expect(await storage.read('project.project-a.key'), aBefore);
        await manager.rotate('project-a');

        expect(await storage.read('project.project-a.key'), isNot(aBefore));
        expect(await storage.read('project.project-b.key'), bBefore);
      },
    );
  });
}
