import 'package:url_launcher/url_launcher.dart';

import '../../../../core/entities/operation_result.dart';
import '../../domain/entities/field_rule.dart';
import '../../domain/repositories/external_link_repository.dart';

class ExternalLinkRepositoryImpl implements ExternalLinkRepository {
  const ExternalLinkRepositoryImpl();

  @override
  Future<OperationResult<bool>> open({
    required FieldRuleKind kind,
    required String value,
  }) async {
    final uri = switch (kind) {
      FieldRuleKind.phone => Uri(scheme: 'tel', path: value),
      FieldRuleKind.link => _linkUri(value),
      _ => null,
    };
    if (uri == null || !_isAllowed(kind, uri)) {
      return const OperationFailure<bool>('This value cannot be opened.');
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        return const OperationFailure<bool>('No app could open this value.');
      }
      return const OperationSuccess<bool>(true);
    } catch (_) {
      return const OperationFailure<bool>('Could not open this value.');
    }
  }

  Uri? _linkUri(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.hasScheme) return parsed;
    return Uri.tryParse(
      value.startsWith('//') ? 'https:$value' : 'https://$value',
    );
  }

  bool _isAllowed(FieldRuleKind kind, Uri uri) => switch (kind) {
    FieldRuleKind.phone => uri.scheme == 'tel' && uri.path.isNotEmpty,
    FieldRuleKind.link =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          !uri.host.contains(' '),
    _ => false,
  };
}
