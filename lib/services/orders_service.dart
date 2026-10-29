import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_client.dart';
import '../core/config/api_endpoints.dart';
import '../models/order_model.dart';

class OrdersService {
  final ApiClient _apiClient;

  OrdersService(this._apiClient);

  /// Fetch shipments from live backend with pagination support
  Future<({List<OrderModel> shipments, int currentPage, int lastPage, int total})> fetchShipments({
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.shipments}?page=$page',
    );

    if (response is Map<String, dynamic>) {
      final shipmentsJson = response['shipments'] as List? ?? [];
      final paginationJson = response['pagination'] as Map<String, dynamic>? ?? {};

      final shipments = shipmentsJson
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final currentPage = paginationJson['current_page'] as int? ?? page;
      final lastPage = paginationJson['last_page'] as int? ?? 1;
      final total = paginationJson['total'] as int? ?? shipments.length;

      return (
        shipments: shipments,
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
      );
    }

    return (shipments: <OrderModel>[], currentPage: 1, lastPage: 1, total: 0);
  }

  /// Fetch dashboard counters
  Future<Map<String, int>> fetchDashboard() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      if (response is Map<String, dynamic> && response['dashboard'] is Map) {
        final d = response['dashboard'] as Map<String, dynamic>;
        final outForDeliveryCount = (d['out_for_delivery'] as num?)?.toInt() ??
            (d['in_transit'] as num?)?.toInt() ??
            0;
        final pendingCount = (d['pending'] as num?)?.toInt() ??
            (d['booked'] as num?)?.toInt() ??
            0;

        return {
          'total': (d['total_shipments'] as num?)?.toInt() ?? 0,
          'pending': pendingCount,
          'out_for_delivery': outForDeliveryCount,
          'in_transit': outForDeliveryCount, // Backward compatibility
          'delivered': (d['delivered'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {
      'total': 0,
      'pending': 0,
      'out_for_delivery': 0,
      'in_transit': 0,
      'delivered': 0,
    };
  }

  /// Format date helper to guarantee dd-MM-yyyy (e.g. 28-10-2026) as expected by backend API
  String _normalizeDeliveryDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      final now = DateTime.now();
      final d = now.day.toString().padLeft(2, '0');
      final m = now.month.toString().padLeft(2, '0');
      return '$d-$m-${now.year}';
    }
    final clean = rawDate.trim().split('T').first;
    if (clean.contains('-')) {
      final parts = clean.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // yyyy-MM-dd -> dd-MM-yyyy
          return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
        } else if (parts[2].length == 4) {
          // already dd-MM-yyyy
          return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
        }
      }
    }
    return clean;
  }

  /// Update shipment status according to backend curl specification:
  /// POST /delivery-boy/shipments/{id}/status
  /// multipart/form-data with status, current_location, remarks, delivery_date, and pod_file
  Future<bool> updateShipmentStatus({
    required dynamic shipmentId,
    required OrderStatus newStatus,
    String? currentLocation,
    String? remarks,
    String? deliveryDate,
    String? podFilePath,
  }) async {
    final loc = (currentLocation != null && currentLocation.trim().isNotEmpty)
        ? currentLocation.trim()
        : 'Hub';

    final effectiveDate = _normalizeDeliveryDate(deliveryDate);

    final formDataMap = <String, dynamic>{
      'status': newStatus.apiValue, // 'Booked', 'OUT_FOR_DELIVERY', 'DELIVERED', 'FAILED'
      'current_location': loc,
      'delivery_date': effectiveDate,
    };

    if (remarks != null && remarks.trim().isNotEmpty) {
      formDataMap['remarks'] = remarks.trim();
    }

    if (podFilePath != null && podFilePath.isNotEmpty && File(podFilePath).existsSync()) {
      formDataMap['pod_file'] = await MultipartFile.fromFile(
        podFilePath,
        filename: podFilePath.split(Platform.pathSeparator).last,
      );
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _apiClient.post(
      ApiEndpoints.updateShipmentStatus(shipmentId),
      data: formData,
    );

    if (response is Map && response['success'] == false) {
      throw response['message']?.toString() ?? 'Status update rejected by server.';
    }
    return true;
  }
}

/// Provider for OrdersService
final ordersServiceProvider = Provider<OrdersService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersService(apiClient);
});
