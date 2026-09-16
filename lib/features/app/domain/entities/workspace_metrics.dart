class WorkspaceMetrics {
  const WorkspaceMetrics({
    required this.templates,
    required this.fonts,
    required this.certificates,
  });

  const WorkspaceMetrics.empty()
    : templates = 0,
      fonts = 0,
      certificates = 0;

  final int templates;
  final int fonts;
  final int certificates;
}
