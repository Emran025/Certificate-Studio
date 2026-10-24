Future<void> ensureProjectWorkspace(String projectId) async {}

Future<String?> saveProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
  required List<int> bytes,
}) async => null;

Future<List<int>?> readProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) async => null;

Future<void> deleteProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) async {}

Future<void> deleteProjectWorkspace(String projectId) async {}
