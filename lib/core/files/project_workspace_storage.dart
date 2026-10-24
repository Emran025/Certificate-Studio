import 'project_workspace_storage_stub.dart'
    if (dart.library.io) 'project_workspace_storage_io.dart'
    as platform;

Future<void> ensureProjectWorkspace(String projectId) =>
    platform.ensureProjectWorkspace(projectId);

Future<String?> saveProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
  required List<int> bytes,
}) => platform.saveProjectWorkspaceFile(
  projectId: projectId,
  relativePath: relativePath,
  bytes: bytes,
);

Future<List<int>?> readProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) => platform.readProjectWorkspaceFile(
  projectId: projectId,
  relativePath: relativePath,
);

Future<void> deleteProjectWorkspaceFile({
  required String projectId,
  required String relativePath,
}) => platform.deleteProjectWorkspaceFile(
  projectId: projectId,
  relativePath: relativePath,
);

Future<void> deleteProjectWorkspace(String projectId) =>
    platform.deleteProjectWorkspace(projectId);
