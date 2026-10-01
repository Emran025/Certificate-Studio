part of '../certificate_library_screen.dart';

class _CertificateExportOptions {
  const _CertificateExportOptions({
    required this.field,
    required this.extensions,
    required this.style,
  });

  final String field;
  final Set<String> extensions;
  final CertificateExportBundleStyle style;
}
