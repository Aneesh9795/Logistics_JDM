import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/token_storage.dart';
import '../models/order_model.dart';
import '../services/orders_service.dart';

enum OrderFilterType {
  total,
  pending,
  outForDelivery,
  delivered;

  // Backward compatibility alias
  static const OrderFilterType inTransit = OrderFilterType.outForDelivery;

  String get label {
    switch (this) {
      case OrderFilterType.total:
        return 'Total';
      case OrderFilterType.pending:
        return 'Booked';
      case OrderFilterType.outForDelivery:
        return 'Out For Delivery';
      case OrderFilterType.delivered:
        return 'Delivered';
    }
  }
}

class OrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSyncing;
  final bool isOffline;
  final int currentPage;
  final int lastPage;
  final int totalCountFromApi;
  final Map<String, int> dashboardCounts;
  final OrderFilterType selectedFilter;
  final String searchQuery;
  final bool isTableView;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const OrdersState({
    required this.orders,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSyncing = false,
    this.isOffline = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalCountFromApi = 0,
    this.dashboardCounts = const {
      'total': 0,
      'pending': 0,
      'out_for_delivery': 0,
      'in_transit': 0,
      'delivered': 0,
    },
    this.selectedFilter = OrderFilterType.total,
    this.searchQuery = '',
    this.isTableView = true,
    this.errorMessage,
    this.lastSyncedAt,
  });

  List<OrderModel> get filteredOrders {
    return orders.where((order) {
      final bool matchesFilter;
      switch (selectedFilter) {
        case OrderFilterType.total:
          matchesFilter = true;
          break;
        case OrderFilterType.pending:
          matchesFilter = order.status != OrderStatus.delivered &&
              order.status != OrderStatus.failed &&
              order.status != OrderStatus.outForDelivery;
          break;
        case OrderFilterType.outForDelivery:
          matchesFilter = order.status == OrderStatus.outForDelivery;
          break;
        case OrderFilterType.delivered:
          matchesFilter = order.status == OrderStatus.delivered;
          break;
      }

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
  int get outForDeliveryCount => dashboardCounts['out_for_delivery'] ?? dashboardCounts['in_transit'] ?? orders.where((o) => o.status == OrderStatus.outForDelivery).length;
  int get inTransitCount => outForDeliveryCount; // Backwards-compatible alias
  int get pendingCount => dashboardCounts['pending'] ?? dashboardCounts['booked'] ?? orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.failed && o.status != OrderStatus.outForDelivery).length;
  int get failedCount => orders.where((o) => o.status == OrderStatus.failed).length;

  OrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSyncing,
    bool? isOffline,
    int? currentPage,
    int? lastPage,
    int? totalCountFromApi,
    Map<String, int>? dashboardCounts,
    OrderFilterType? selectedFilter,
    String? searchQuery,
    bool? isTableView,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSyncing: isSyncing ?? this.isSyncing,
      isOffline: isOffline ?? this.isOffline,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalCountFromApi: totalCountFromApi ?? this.totalCountFromApi,
      dashboardCounts: dashboardCounts ?? this.dashboardCounts,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isTableView: isTableView ?? this.isTableView,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> with WidgetsBindingObserver {
  final OrdersService _ordersService;
  final TokenStorage? _tokenStorage;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isDisposed = false;

  OrdersNotifier(this._ordersService, [this._tokenStorage]) : super(const OrdersState(orders: [])) {
    WidgetsBinding.instance.addObserver(this);
    _initConnectivityListener();
    loadOrders();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed) {
      // Single hit only when delivery partner opens/resumes the app
      silentSync();
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (_isDisposed) return;
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        if (state.isOffline || state.errorMessage != null) {
          // Automatic recovery: Reconnected after disconnect -> single reload
          loadOrders();
        } else {
          silentSync();
        }
      } else {
        state = state.copyWith(isOffline: true);
      }
    });
  }

  List<OrderModel> _enrichWithLocalPod(List<OrderModel> shipments) {
    if (_tokenStorage == null) return shipments;
    return shipments.map((s) {
      if (s.podFile != null && s.podFile!.isNotEmpty) return s;
      final localPath = _tokenStorage.getLocalPodPath(s.docketNo);
      if (localPath != null && localPath.isNotEmpty) {
        return s.copyWith(podFile: localPath);
      }
      return s;
    }).toList();
  }

  /// Initial full load from live backend
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
        isOffline: false,
        errorMessage: null,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isNetError = errStr.contains('network') ||
          errStr.contains('connection') ||
          errStr.contains('timed out') ||
          errStr.contains('socket');

      state = state.copyWith(
        isLoading: false,
        isOffline: isNetError,
        errorMessage: e.toString(),
      );
    }
  }

  /// Silent background sync (no UI flicker or skeleton loaders)
  Future<void> silentSync() async {
    if (state.isLoading || state.isSyncing || _isDisposed) return;
    if (_tokenStorage != null && !_tokenStorage.hasToken()) return;

    state = state.copyWith(isSyncing: true);

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

      final enrichedPage1 = _enrichWithLocalPod(shipmentData.shipments);

      // 1. Existing orders lookup
      final existingMap = {for (final o in state.orders) o.id: o};
      final page1Ids = enrichedPage1.map((o) => o.id).toSet();

      // 2. Identify brand-new orders created by admin (present in page 1, not in existing state)
      final newOrders = enrichedPage1.where((o) => !existingMap.containsKey(o.id)).toList();

      // 3. Update status/fields of orders already displayed
      final updatedExisting = state.orders.map((existingOrder) {
        if (page1Ids.contains(existingOrder.id)) {
          return enrichedPage1.firstWhere((o) => o.id == existingOrder.id);
        }
        return existingOrder;
      }).toList();

      // 4. Place new orders at top, preserve any paginated orders below
      final combined = [...newOrders, ...updatedExisting];

      if (!_isDisposed) {
        state = state.copyWith(
          orders: combined,
          dashboardCounts: dashboardData,
          totalCountFromApi: shipmentData.total,
          lastPage: shipmentData.lastPage,
          isSyncing: false,
          isOffline: false,
          errorMessage: null,
          lastSyncedAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        final errStr = e.toString().toLowerCase();
        final isNetError = errStr.contains('network') ||
            errStr.contains('connection') ||
            errStr.contains('timed out') ||
            errStr.contains('socket');

        final isSessionExpired = errStr.contains('session expired') || errStr.contains('unauthenticated');
        if (isSessionExpired) {
          state = state.copyWith(
            isSyncing: false,
            errorMessage: 'Session expired. Please login again.',
          );
        } else {
          state = state.copyWith(
            isSyncing: false,
            isOffline: isNetError ? true : state.isOffline,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Lazy loading / Pagination (load next page with deduplication & pre-emptive trigger)
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.lastPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _ordersService.fetchShipments(page: nextPage);

      // Fast ID-based deduplication to prevent duplicate cards
      final existingIds = state.orders.map((o) => o.id).toSet();
      final newUniqueShipments = result.shipments.where((o) => !existingIds.contains(o.id)).toList();

      final combined = _enrichWithLocalPod([...state.orders, ...newUniqueShipments]);

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

  void setFilter(OrderFilterType filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleViewMode() {
    state = state.copyWith(isTableView: !state.isTableView);
  }

  /// Live status update (Out For Delivery, Booked, etc.)
  Future<({bool success, String? error})> updateOrderStatus(
    String docketNo,
    OrderStatus newStatus, {
    String? location,
    String? remarks,
  }) async {
    final order = getOrderByDocketNo(docketNo);
    if (order == null) return (success: false, error: 'Order not found');

    final previousOrder = order;
    final loc = (location != null && location.trim().isNotEmpty)
        ? location.trim()
        : (order.deliveryLocation.isNotEmpty
            ? order.deliveryLocation
            : (order.pickupLocation.isNotEmpty ? order.pickupLocation : 'Hub'));

    // Optimistic UI update
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(status: newStatus, currentLocation: loc);
        }
        return o;
      }).toList(),
    );

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: newStatus,
        currentLocation: loc,
        remarks: remarks ??
            (order.remarks?.isNotEmpty == true
                ? order.remarks
                : (newStatus == OrderStatus.outForDelivery ? 'Out for delivery' : 'Status updated')),
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

  /// Mark Delivered with live POD upload matching curl parameters
  Future<({bool success, String? error})> markOrderDelivered(
    String docketNo, {
    String? invoiceImagePath,
    String? remarks,
  }) async {
    final order = getOrderByDocketNo(docketNo);
    if (order == null) return (success: false, error: 'Order not found');

    final previousOrder = order;
    final loc = order.deliveryLocation.isNotEmpty
        ? order.deliveryLocation
        : (order.fullDeliveryAddress.isNotEmpty ? order.fullDeliveryAddress : 'Delivered');

    // Optimistic UI update
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(
            status: OrderStatus.delivered,
            podFile: invoiceImagePath,
            completedAt: DateTime.now(),
            currentLocation: loc,
          );
        }
        return o;
      }).toList(),
    );

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: OrderStatus.delivered,
        currentLocation: loc,
        remarks: (remarks != null && remarks.trim().isNotEmpty)
            ? remarks.trim()
            : (order.remarks?.trim().isNotEmpty == true ? order.remarks! : 'Delivered successfully'),
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
    final loc = order.deliveryLocation.isNotEmpty
        ? order.deliveryLocation
        : (order.pickupLocation.isNotEmpty ? order.pickupLocation : 'Hub');

    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.docketNo == docketNo) {
          return o.copyWith(
            status: OrderStatus.failed,
            failedReason: reason,
            completedAt: DateTime.now(),
            currentLocation: loc,
          );
        }
        return o;
      }).toList(),
    );

    try {
      await _ordersService.updateShipmentStatus(
        shipmentId: order.id,
        newStatus: OrderStatus.failed,
        currentLocation: loc,
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
