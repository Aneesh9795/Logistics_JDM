import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_client.dart';
import '../core/config/api_endpoints.dart';
import '../models/order_model.dart';

class OrdersService {
  final ApiClient _apiClient;

  OrdersService(this._apiClient);

  /// Fetch orders list from backend
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.orders);
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is List) {
        return response
            .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      rethrow;
    }
  }

  /// Update order status (Picked up, Delivered, Failed)
  Future<bool> updateOrderStatus({
    required String docketNo,
    required OrderStatus newStatus,
    String? failedReason,
    String? invoiceImagePath,
  }) async {
    try {
      final payload = <String, dynamic>{
        'docket_no': docketNo,
        'status': newStatus.label,
      };
      if (failedReason != null) payload['failed_reason'] = failedReason;
      if (invoiceImagePath != null) payload['invoice_image_path'] = invoiceImagePath;

      await _apiClient.post(
        ApiEndpoints.updateStatus,
        data: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider for OrdersService
final ordersServiceProvider = Provider<OrdersService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrdersService(apiClient);
});
