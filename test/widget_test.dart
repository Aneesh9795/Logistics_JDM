import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistic_jmd/core/config/api_client.dart';
import 'package:logistic_jmd/core/storage/token_storage.dart';
import 'package:logistic_jmd/main.dart';
import 'package:logistic_jmd/models/order_model.dart';
import 'package:logistic_jmd/pages/home_page.dart';
import 'package:logistic_jmd/pages/order_detail_page.dart';
import 'package:logistic_jmd/providers/orders_provider.dart';
import 'package:logistic_jmd/services/orders_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final deviceSizes = [
    const Size(320, 568),   // Small 4" budget Android phone
    const Size(360, 780),   // Compact 5.5" Android phone
    const Size(390, 844),   // Standard 6.1" Android phone
    const Size(412, 915),   // Large modern 6.7" Android phone (Pixel/Galaxy)
    const Size(600, 1024),  // 7" to 8" Android Tablet Portrait
    const Size(800, 1280),  // 10" Android Tablet Portrait
    const Size(1280, 800),  // 10" Android Tablet Landscape
  ];

  const mockOrder = OrderModel(
    id: 101,
    docketNo: 'JMD-98765',
    status: OrderStatus.inTransit,
    pickupLocation: 'Delhi Hub',
    deliveryLocation: 'Mumbai Warehouse',
    weight: '15.5',
    pieces: '3',
    customerCompany: 'ABC Exports Ltd',
    consigneeName: 'XYZ Retailers Pvt Ltd',
    consigneeContact: '9876543210',
    fullDeliveryAddress: 'Plot 42, Industrial Area Phase 2, Andheri East, Mumbai',
    pickupDate: '2026-10-20',
  );

  testWidgets('App launch & Login screen multi-device responsiveness', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = TokenStorage(prefs);

    for (final size in deviceSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokenStorage),
          ],
          child: const JMDLogisticsApp(),
        ),
      );

      expect(find.byType(JMDLogisticsApp), findsOneWidget);

      // Advance through splash animations to login page
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 500));

      addTearDown(tester.view.resetPhysicalSize);
    }
  });

  testWidgets('HomePage responsiveness across all Android phones and tablets', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = TokenStorage(prefs);

    for (final size in deviceSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokenStorage),
            ordersProvider.overrideWith((ref) => MockOrdersNotifier([mockOrder], tokenStorage)),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('In Transit'), findsWidgets);
      expect(find.text('Delivered'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    }
  });

  testWidgets('OrderDetailPage responsiveness across all Android phones and tablets', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = TokenStorage(prefs);

    for (final size in deviceSizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokenStorage),
            ordersProvider.overrideWith((ref) => MockOrdersNotifier([mockOrder], tokenStorage)),
          ],
          child: const MaterialApp(
            home: OrderDetailPage(docketNo: 'JMD-98765'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Docket: JMD-98765'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    }
  });
}

class FakeOrdersService extends OrdersService {
  FakeOrdersService(TokenStorage tokenStorage) : super(ApiClient(tokenStorage));

  @override
  Future<({List<OrderModel> shipments, int currentPage, int lastPage, int total})> fetchShipments({int page = 1}) async {
    return (shipments: <OrderModel>[], currentPage: 1, lastPage: 1, total: 0);
  }
}

class MockOrdersNotifier extends OrdersNotifier {
  MockOrdersNotifier(List<OrderModel> mockOrders, TokenStorage tokenStorage)
      : super(FakeOrdersService(tokenStorage), tokenStorage) {
    state = OrdersState(
      orders: mockOrders,
      isLoading: false,
    );
  }

  @override
  Future<void> loadOrders() async {}

  @override
  Future<void> refresh() async {}
}
