import '../../../../core/entities/operation_result.dart';
import '../entities/field_rule.dart';
import '../repositories/external_link_repository.dart';

class OpenExternalLink {
  const OpenExternalLink(this._repository);

  final ExternalLinkRepository _repository;

  Future<OperationResult<bool>> call({
    required FieldRuleKind kind,
    required String value,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        (kind != FieldRuleKind.phone && kind != FieldRuleKind.link)) {
      return Future.value(
        const OperationFailure<bool>('This value cannot be opened.'),
      );
    }
    return _repository.open(kind: kind, value: trimmed);
  }
}
