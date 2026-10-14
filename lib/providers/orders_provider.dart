import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final OrderStatus? selectedFilter;
  final String searchQuery;
  final bool isTableView;

  const OrdersState({
    required this.orders,
    this.isLoading = false,
    this.selectedFilter,
    this.searchQuery = '',
    this.isTableView = true,
  });

  List<OrderModel> get filteredOrders {
    return orders.where((order) {
      final matchesFilter = selectedFilter == null || order.status == selectedFilter;
      final matchesSearch = searchQuery.isEmpty ||
          order.docketNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.from.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.to.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.sNo.toString() == searchQuery.trim();
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // Groups the filtered orders by Date (e.g. '01-08-2026', '02-08-2026')
  Map<String, List<OrderModel>> get groupedOrdersByDate {
    final map = <String, List<OrderModel>>{};
    for (final order in filteredOrders) {
      final dateKey = order.orderDate.isNotEmpty ? order.orderDate : 'Unscheduled';
      map.putIfAbsent(dateKey, () => []).add(order);
    }
    return map;
  }

  int get totalCount => orders.length;
  int get deliveredCount => orders.where((o) => o.status == OrderStatus.delivered).length;
  int get failedCount => orders.where((o) => o.status == OrderStatus.failed).length;
  int get pendingCount => orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed).length;

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    OrderStatus? Function()? selectedFilter,
    String? searchQuery,
    bool? isTableView,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      selectedFilter: selectedFilter != null ? selectedFilter() : this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isTableView: isTableView ?? this.isTableView,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersService _ordersService;

  OrdersNotifier(this._ordersService)
      : super(const OrdersState(orders: _initialExcelOrders));

  // Load orders from API
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final orders = await _ordersService.fetchOrders();
      if (orders.isNotEmpty) {
        state = state.copyWith(orders: orders, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Refresh alias
  Future<void> refresh() => loadOrders();

  void setFilter(OrderStatus? filter) {
    state = state.copyWith(selectedFilter: () => filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleViewMode() {
    state = state.copyWith(isTableView: !state.isTableView);
  }

  void updateOrderStatus(String docketNo, OrderStatus newStatus) {
    _ordersService.updateOrderStatus(docketNo: docketNo, newStatus: newStatus);

    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(status: newStatus);
        }
        return o;
      }).toList(),
    );
  }

  void markOrderDelivered(String docketNo, {String? invoiceImagePath}) {
    _ordersService.updateOrderStatus(
      docketNo: docketNo,
      newStatus: OrderStatus.delivered,
      invoiceImagePath: invoiceImagePath,
    );

    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(
            status: OrderStatus.delivered,
            invoiceImagePath: invoiceImagePath,
            completedAt: DateTime.now(),
          );
        }
        return o;
      }).toList(),
    );
  }

  // Compatibility alias
  void markAsDelivered(String docketNo, [String? invoiceImagePath]) =>
      markOrderDelivered(docketNo, invoiceImagePath: invoiceImagePath);

  void markOrderFailed(String docketNo, String reason) {
    _ordersService.updateOrderStatus(
      docketNo: docketNo,
      newStatus: OrderStatus.failed,
      failedReason: reason,
    );

    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(
            status: OrderStatus.failed,
            failedReason: reason,
            completedAt: DateTime.now(),
          );
        }
        return o;
      }).toList(),
    );
  }

  // Compatibility alias
  void markAsFailed(String docketNo, String reason) =>
      markOrderFailed(docketNo, reason);

  OrderModel? getOrderByDocketNo(String docketNo) {
    try {
      return state.orders.firstWhere((o) => o.docketNo == docketNo);
    } catch (_) {
      return null;
    }
  }

  // Pre-loaded verified orders
  static const List<OrderModel> _initialExcelOrders = [
    OrderModel(
      sNo: 2,
      deliveryDate: '03-08-2026',
      orderDate: '01-08-2026',
      docketNo: '266907',
      from: 'Pacific Mall',
      to: 'Ambience GGN',
      brand: 'CK',
      noOfBoxes: '1 Box',
      status: OrderStatus.newOrder,
    ),
    OrderModel(
      sNo: 17,
      deliveryDate: '01-08-2026',
      orderDate: '01-08-2026',
      docketNo: '292887',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Ambience ND',
      brand: 'BBW',
      noOfBoxes: '7 Box',
      status: OrderStatus.inTransit,
    ),
    OrderModel(
      sNo: 11,
      deliveryDate: '03-08-2026',
      orderDate: '01-08-2026',
      docketNo: '291880',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Ambience ND',
      brand: 'Crocs',
      noOfBoxes: '3 Box',
      status: OrderStatus.pickedUp,
    ),
    OrderModel(
      sNo: 24,
      deliveryDate: '03-08-2026',
      orderDate: '01-08-2026',
      docketNo: '292895',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Pacific Mall',
      brand: 'VS',
      noOfBoxes: '5 Box',
      status: OrderStatus.delivered,
    ),
    OrderModel(
      sNo: 35,
      deliveryDate: '04-08-2026',
      orderDate: '02-08-2026',
      docketNo: '292911',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Select Citywalk',
      brand: 'Zara',
      noOfBoxes: '2 Box',
      status: OrderStatus.newOrder,
    ),
  ];
}

/// Riverpod provider for OrdersNotifier
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final ordersService = ref.watch(ordersServiceProvider);
  return OrdersNotifier(ordersService);
});

/// Riverpod family provider for single order by docketNo
final singleOrderProvider = Provider.family<OrderModel?, String>((ref, docketNo) {
  return ref.watch(ordersProvider.select((state) {
    try {
      return state.orders.firstWhere((o) => o.docketNo == docketNo);
    } catch (_) {
      return null;
    }
  }));
});
