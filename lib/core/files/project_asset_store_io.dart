import 'project_workspace_storage.dart';

Future<String?> saveProjectBackground({
  required String projectId,
  required String fileName,
  required List<int> bytes,
}) async {
  await ensureProjectWorkspace(projectId);
  return saveProjectWorkspaceFile(
    projectId: projectId,
    relativePath: 'assets/templates/$fileName',
    bytes: bytes,
  );
}
