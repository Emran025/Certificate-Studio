import 'package:certificate_studio/shared/themes/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps spacing, radius, and breakpoint constants ordered', () {
    expect(AppSpacing.xxs, lessThan(AppSpacing.xs));
    expect(AppSpacing.xs, lessThan(AppSpacing.md));
    expect(AppSpacing.md, lessThan(AppSpacing.huge));
    expect(AppRadius.input, lessThan(AppRadius.card));
    expect(AppRadius.card, lessThan(AppRadius.pill));
    expect(AppBreakpoints.mobile, lessThan(AppBreakpoints.tablet));
    expect(AppBreakpoints.tablet, lessThan(AppBreakpoints.desktop));
  });

  testWidgets('classifies mobile, tablet, and desktop widths', (tester) async {
    Future<void> pumpAt(double width) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) => Text(
              '${AppBreakpoints.isMobile(context)}|'
              '${AppBreakpoints.isTablet(context)}|'
              '${AppBreakpoints.isDesktop(context)}',
            ),
          ),
        ),
      ),
    );

    await pumpAt(599);
    expect(find.text('true|false|false'), findsOneWidget);
    await pumpAt(900);
    expect(find.text('false|true|false'), findsOneWidget);
    await pumpAt(1200);
    expect(find.text('false|false|true'), findsOneWidget);
  });
}
