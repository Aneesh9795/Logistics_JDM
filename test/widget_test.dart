import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistic_jmd/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JMDLogisticsApp(),
      ),
    );
    expect(find.byType(JMDLogisticsApp), findsOneWidget);

    // Advance beyond the splash 1.5s delay
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
