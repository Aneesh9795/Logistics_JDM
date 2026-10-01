import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final OrderStatus? selectedFilter;
  final String searchQuery;

  const OrdersState({
    required this.orders,
    this.isLoading = false,
    this.selectedFilter,
    this.searchQuery = '',
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

  int get totalCount => orders.length;
  int get deliveredCount => orders.where((o) => o.status == OrderStatus.delivered).length;
  int get failedCount => orders.where((o) => o.status == OrderStatus.failed).length;
  int get pendingCount => orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed).length;

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    OrderStatus? Function()? selectedFilter,
    String? searchQuery,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      selectedFilter: selectedFilter != null ? selectedFilter() : this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrdersViewModel extends StateNotifier<OrdersState> {
  OrdersViewModel() : super(OrdersState(orders: _initialExcelOrders));

  // Initial orders populated directly from User's Excel sheet reference
  static final List<OrderModel> _initialExcelOrders = [
    const OrderModel(
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
    const OrderModel(
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
    const OrderModel(
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
    const OrderModel(
      sNo: 7,
      deliveryDate: '08-08-2026',
      orderDate: '01-08-2026',
      docketNo: '267050',
      from: 'Ambience ND',
      to: 'Boulevard Walk (G.Noida)',
      brand: 'BBW',
      noOfBoxes: '1 Box',
      status: OrderStatus.newOrder,
    ),
    const OrderModel(
      sNo: 9,
      deliveryDate: '08-08-2026',
      orderDate: '01-08-2026',
      docketNo: '282017',
      from: 'Dlf Promenade',
      to: 'Boulevard Walk (G.Noida)',
      brand: 'BBW',
      noOfBoxes: '6 Box',
      status: OrderStatus.delivered,
      completedAt: null,
    ),
    const OrderModel(
      sNo: 8,
      deliveryDate: '08-08-2026',
      orderDate: '01-08-2026',
      docketNo: '281534',
      from: 'Elegante Mall',
      to: 'Boulevard Walk (G.Noida)',
      brand: 'BBW',
      noOfBoxes: '1 Box',
      status: OrderStatus.failed,
      failedReason: 'Store closed by mall authority',
    ),
    const OrderModel(
      sNo: 10,
      deliveryDate: '08-08-2026',
      orderDate: '01-08-2026',
      docketNo: '291568',
      from: 'Felix Plaza',
      to: 'Boulevard Walk (G.Noida)',
      brand: 'BBW',
      noOfBoxes: '4 Box',
      status: OrderStatus.newOrder,
    ),
    const OrderModel(
      sNo: 1,
      deliveryDate: '08-08-2026',
      orderDate: '01-08-2026',
      docketNo: '266906',
      from: 'Pacific Mall',
      to: 'Boulevard Walk (G.Noida)',
      brand: 'BBW',
      noOfBoxes: '2 Box',
      status: OrderStatus.inTransit,
    ),
    const OrderModel(
      sNo: 16,
      deliveryDate: '03-08-2026',
      orderDate: '01-08-2026',
      docketNo: '291886',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Dlf Summit Plaza',
      brand: 'BBW',
      noOfBoxes: '28 Box',
      status: OrderStatus.newOrder,
    ),
    const OrderModel(
      sNo: 13,
      deliveryDate: '04-08-2026',
      orderDate: '01-08-2026',
      docketNo: '291882',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Elan Epic',
      brand: 'Crocs',
      noOfBoxes: '5 Box',
      status: OrderStatus.pickedUp,
    ),
    const OrderModel(
      sNo: 4,
      deliveryDate: '03-08-2026',
      orderDate: '01-08-2026',
      docketNo: '266909',
      from: 'Pacific Mall',
      to: 'Elegante Mall',
      brand: 'CK',
      noOfBoxes: '1 Box',
      status: OrderStatus.newOrder,
    ),
    const OrderModel(
      sNo: 15,
      deliveryDate: '01-08-2026',
      orderDate: '01-08-2026',
      docketNo: '291885',
      from: 'LF Logistics (Farukh Nagar)',
      to: 'Felix Plaza',
      brand: 'BBW',
      noOfBoxes: '37 Box',
      status: OrderStatus.newOrder,
    ),
  ];

  OrderModel? getOrderByDocket(String docketNo) {
    try {
      return state.orders.firstWhere((o) => o.docketNo == docketNo);
    } catch (_) {
      return null;
    }
  }

  void markAsDelivered(String docketNo, String invoiceImagePath) {
    final updatedList = state.orders.map((order) {
      if (order.docketNo == docketNo) {
        return order.copyWith(
          status: OrderStatus.delivered,
          invoiceImagePath: invoiceImagePath,
          failedReason: null,
          completedAt: DateTime.now(),
        );
      }
      return order;
    }).toList();

    state = state.copyWith(orders: updatedList);
  }

  void markAsFailed(String docketNo, String reason) {
    final updatedList = state.orders.map((order) {
      if (order.docketNo == docketNo) {
        return order.copyWith(
          status: OrderStatus.failed,
          failedReason: reason.trim(),
          completedAt: DateTime.now(),
        );
      }
      return order;
    }).toList();

    state = state.copyWith(orders: updatedList);
  }

  void setFilter(OrderStatus? filter) {
    state = state.copyWith(
      selectedFilter: () => filter,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(isLoading: false);
  }
}

final ordersViewModelProvider = StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
  return OrdersViewModel();
});

// Selector provider for a single order by docketNo
final singleOrderProvider = Provider.family<OrderModel?, String>((ref, docketNo) {
  final orders = ref.watch(ordersViewModelProvider).orders;
  try {
    return orders.firstWhere((o) => o.docketNo == docketNo);
  } catch (_) {
    return null;
  }
});
