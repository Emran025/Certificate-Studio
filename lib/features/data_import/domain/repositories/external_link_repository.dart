import '../../../../core/entities/operation_result.dart';
import '../entities/field_rule.dart';

abstract interface class ExternalLinkRepository {
  Future<OperationResult<bool>> open({
    required FieldRuleKind kind,
    required String value,
  });
}
