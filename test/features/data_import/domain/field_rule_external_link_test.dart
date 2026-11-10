import 'package:certificate_studio/core/entities/operation_result.dart';
import 'package:certificate_studio/features/data_import/domain/entities/field_rule.dart';
import 'package:certificate_studio/features/data_import/domain/repositories/external_link_repository.dart';
import 'package:certificate_studio/features/data_import/domain/usecases/open_external_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'serializes phone and link and keeps unknown kinds backward compatible',
    () {
      const phone = FieldRule(kind: FieldRuleKind.phone);
      const link = FieldRule(kind: FieldRuleKind.link);

      expect(FieldRule.fromJson(phone.toJson()).kind, FieldRuleKind.phone);
      expect(FieldRule.fromJson(link.toJson()).kind, FieldRuleKind.link);
      expect(
        FieldRule.fromJson({'kind': 'legacy-kind'}).kind,
        FieldRuleKind.text,
      );
      expect(FieldRule.fromJson({'min': 1, 'max': 2}).kind, FieldRuleKind.text);
    },
  );

  test('external-link use case rejects unsupported and blank values', () async {
    final repository = _FakeExternalLinkRepository();
    final open = OpenExternalLink(repository);

    expect(
      await open(kind: FieldRuleKind.text, value: 'https://example.com'),
      isA<OperationFailure<bool>>(),
    );
    expect(
      await open(kind: FieldRuleKind.link, value: '  '),
      isA<OperationFailure<bool>>(),
    );
    expect(repository.calls, isEmpty);
  });

  test('external-link use case forwards supported values', () async {
    final repository = _FakeExternalLinkRepository();
    final open = OpenExternalLink(repository);

    expect(
      await open(kind: FieldRuleKind.link, value: ' https://example.com '),
      isA<OperationSuccess<bool>>(),
    );
    expect(repository.calls.single, (
      FieldRuleKind.link,
      'https://example.com',
    ));
  });
}

class _FakeExternalLinkRepository implements ExternalLinkRepository {
  final calls = <(FieldRuleKind, String)>[];

  @override
  Future<OperationResult<bool>> open({
    required FieldRuleKind kind,
    required String value,
  }) async {
    calls.add((kind, value));
    return const OperationSuccess<bool>(true);
  }
}
