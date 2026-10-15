import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/token_storage.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final int totalCountFromApi;
  final Map<String, int> dashboardCounts;
  final OrderStatus? selectedFilter;
  final String searchQuery;
  final bool isTableView;
  final String? errorMessage;

  const OrdersState({
    required this.orders,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalCountFromApi = 0,
    this.dashboardCounts = const {
      'total': 0,
      'pending': 0,
      'in_transit': 0,
      'delivered': 0,
    },
    this.selectedFilter,
    this.searchQuery = '',
    this.isTableView = true,
    this.errorMessage,
  });

  List<OrderModel> get filteredOrders {
    return orders.where((order) {
      final matchesFilter = selectedFilter == null || order.status == selectedFilter;
      final matchesSearch = searchQuery.isEmpty ||
          order.docketNo.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.from.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.to.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.consigneeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          order.sNo.toString() == searchQuery.trim();
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // Groups the filtered orders by Date (e.g. '2026-10-02')
  Map<String, List<OrderModel>> get groupedOrdersByDate {
    final map = <String, List<OrderModel>>{};
    for (final order in filteredOrders) {
      final dateKey = order.orderDate.isNotEmpty ? order.orderDate : 'Unscheduled';
      map.putIfAbsent(dateKey, () => []).add(order);
    }
    return map;
  }

  // Dashboard Stats Getters
  int get totalCount => dashboardCounts['total'] ?? orders.length;
  int get deliveredCount => dashboardCounts['delivered'] ?? orders.where((o) => o.status == OrderStatus.delivered).length;
  int get inTransitCount => dashboardCounts['in_transit'] ?? orders.where((o) => o.status == OrderStatus.inTransit).length;
  int get pendingCount => dashboardCounts['pending'] ?? orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed).length;
  int get failedCount => orders.where((o) => o.status == OrderStatus.failed).length;

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    int? totalCountFromApi,
    Map<String, int>? dashboardCounts,
    OrderStatus? Function()? selectedFilter,
    String? searchQuery,
    bool? isTableView,
    String? errorMessage,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalCountFromApi: totalCountFromApi ?? this.totalCountFromApi,
      dashboardCounts: dashboardCounts ?? this.dashboardCounts,
      selectedFilter: selectedFilter != null ? selectedFilter() : this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isTableView: isTableView ?? this.isTableView,
      errorMessage: errorMessage,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersService _ordersService;
  final TokenStorage? _tokenStorage;

  OrdersNotifier(this._ordersService, [this._tokenStorage]) : super(const OrdersState(orders: [])) {
    loadOrders();
  }

  List<OrderModel> _enrichWithLocalPod(List<OrderModel> shipments) {
    if (_tokenStorage == null) return shipments;
    return shipments.map((s) {
      final localPath = _tokenStorage.getLocalPodPath(s.docketNo);
      if (localPath != null && !kIsWeb && File(localPath).existsSync()) {
        return s.copyWith(podFile: localPath);
      }
      return s;
    }).toList();
  }

  /// Initial load from live backend
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final shipmentsFuture = _ordersService.fetchShipments(page: 1);
      final dashboardFuture = _ordersService.fetchDashboard();

      final results = await Future.wait([shipmentsFuture, dashboardFuture]);

      final shipmentData = results[0] as ({
        List<OrderModel> shipments,
        int currentPage,
        int lastPage,
        int total
      });
      final dashboardData = results[1] as Map<String, int>;

      final enrichedShipments = _enrichWithLocalPod(shipmentData.shipments);

      state = state.copyWith(
        orders: enrichedShipments,
        currentPage: shipmentData.currentPage,
        lastPage: shipmentData.lastPage,
        totalCountFromApi: shipmentData.total,
        dashboardCounts: dashboardData,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Lazy loading / Pagination (load next page)
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.currentPage >= state.lastPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _ordersService.fetchShipments(page: nextPage);

      final combined = _enrichWithLocalPod([...state.orders, ...result.shipments]);

      state = state.copyWith(
        orders: combined,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        totalCountFromApi: result.total,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh alias for pull-to-refresh
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

  /// Live status update (In Transit, Picked Up)
  Future<({bool success, String? error})> updateOrderStatus(
    String docketNo,
    OrderStatus newStatus, {
    String? location,
    String? remarks,
  }) async {
    final order = getOrderByDocketNo(docketNo);
    if (order == null) return (success: false, error: 'Order not found');

    final previousOrder = order;

    // Optimistic UI update
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(status: newStatus, currentLocation: location ?? o.currentLocation);
        }
        return o;
      }).toList(),
    );

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: newStatus,
        currentLocation: location ?? (order.deliveryLocation.isNotEmpty ? order.deliveryLocation : 'In Transit'),
        remarks: remarks ?? 'Status updated to ${newStatus.label}',
      );
      return (success: true, error: null);
    } catch (e) {
      // Revert optimistic update on failure
      state = state.copyWith(
        orders: state.orders.map((o) => o.docketNo == docketNo ? previousOrder : o).toList(),
      );
      return (success: false, error: e.toString());
    }
  }

  /// Mark Delivered with live POD upload
  Future<({bool success, String? error})> markOrderDelivered(
    String docketNo, {
    String? invoiceImagePath,
  }) async {
    final order = getOrderByDocketNo(docketNo);
    if (order == null) return (success: false, error: 'Order not found');

    final previousOrder = order;

    // Optimistic UI update
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(
            status: OrderStatus.delivered,
            podFile: invoiceImagePath,
            completedAt: DateTime.now(),
          );
        }
        return o;
      }).toList(),
    );

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: OrderStatus.delivered,
        currentLocation: order.deliveryLocation.isNotEmpty ? order.deliveryLocation : 'Delivered',
        remarks: 'Delivered successfully',
        deliveryDate: DateTime.now().toIso8601String().split('T').first,
        podFilePath: invoiceImagePath,
      );
      if (invoiceImagePath != null && invoiceImagePath.isNotEmpty) {
        await _tokenStorage?.saveLocalPodPath(docketNo, invoiceImagePath);
      }
      return (success: true, error: null);
    } catch (e) {
      // Revert optimistic update on failure
      state = state.copyWith(
        orders: state.orders.map((o) => o.docketNo == docketNo ? previousOrder : o).toList(),
      );
      return (success: false, error: e.toString());
    }
  }

  // Compatibility alias
  Future<({bool success, String? error})> markAsDelivered(String docketNo, [String? invoiceImagePath]) =>
      markOrderDelivered(docketNo, invoiceImagePath: invoiceImagePath);

  /// Mark Failed with reason
  Future<({bool success, String? error})> markOrderFailed(String docketNo, String reason) async {
    final order = getOrderByDocketNo(docketNo);
    if (order == null) return (success: false, error: 'Order not found');

    final previousOrder = order;

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

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: OrderStatus.failed,
        remarks: reason,
      );
      return (success: true, error: null);
    } catch (e) {
      state = state.copyWith(
        orders: state.orders.map((o) => o.docketNo == docketNo ? previousOrder : o).toList(),
      );
      return (success: false, error: e.toString());
    }
  }

  // Compatibility alias
  Future<({bool success, String? error})> markAsFailed(String docketNo, String reason) =>
      markOrderFailed(docketNo, reason);

  OrderModel? getOrderByDocketNo(String docketNo) {
    try {
      return state.orders.firstWhere((o) => o.docketNo == docketNo);
    } catch (_) {
      return null;
    }
  }
}

/// Riverpod provider for OrdersNotifier
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final ordersService = ref.watch(ordersServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return OrdersNotifier(ordersService, tokenStorage);
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
