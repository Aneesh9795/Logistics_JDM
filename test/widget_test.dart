import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistic_jmd/core/storage/token_storage.dart';
import 'package:logistic_jmd/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = TokenStorage(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
        ],
        child: const JMDLogisticsApp(),
      ),
    );
    expect(find.byType(JMDLogisticsApp), findsOneWidget);

    // Advance beyond the splash delay
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
  });
}

