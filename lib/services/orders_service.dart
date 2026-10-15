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
        return {
          'total': (d['total_shipments'] as num?)?.toInt() ?? 0,
          'pending': (d['pending'] as num?)?.toInt() ?? 0,
          'in_transit': (d['in_transit'] as num?)?.toInt() ?? 0,
          'delivered': (d['delivered'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'total': 0, 'pending': 0, 'in_transit': 0, 'delivered': 0};
  }

  /// Update shipment status (Supports multipart POD photo upload via POST and normal status via PATCH JSON)
  Future<bool> updateShipmentStatus({
    required dynamic shipmentId,
    required OrderStatus newStatus,
    String? currentLocation,
    String? remarks,
    String? deliveryDate,
    String? podFilePath,
  }) async {
    final loc = (currentLocation != null && currentLocation.isNotEmpty)
        ? currentLocation
        : 'In Transit';

    final hasFile = podFilePath != null && podFilePath.isNotEmpty && File(podFilePath).existsSync();

    if (hasFile) {
      // POD Photo upload with Form-Data via POST (matching backend developer's route)
      final fileName = podFilePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'status': newStatus.label,
        'current_location': loc,
        'remarks': (remarks != null && remarks.isNotEmpty) ? remarks : 'Delivered successfully',
        'pod_file': await MultipartFile.fromFile(podFilePath, filename: fileName),
      });

      final response = await _apiClient.post(
        ApiEndpoints.updateShipmentStatus(shipmentId),
        data: formData,
      );

      if (response is Map && response['success'] == false) {
        throw response['message']?.toString() ?? 'Status update rejected by server.';
      }
      return true;
    } else {
      // Normal status update via PATCH JSON
      final jsonBody = {
        'status': newStatus.label,
        'current_location': loc,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        if (deliveryDate != null && deliveryDate.isNotEmpty) 'delivery_date': deliveryDate,
      };

      try {
        final response = await _apiClient.patch(
          ApiEndpoints.updateShipmentStatus(shipmentId),
          data: jsonBody,
        );

        if (response is Map && response['success'] == false) {
          throw response['message']?.toString() ?? 'Status update rejected by server.';
        }
        return true;
      } catch (e) {
        // Fallback to POST with form-data if backend only accepts POST
        final formData = FormData.fromMap(jsonBody);
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
  }
}

/// Provider for OrdersService
final ordersServiceProvider = Provider<OrdersService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersService(apiClient);
});
