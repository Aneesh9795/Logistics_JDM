class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://jmdlogisticsolutions.com/api';

  // Auth
  static const String login = '/delivery-boy/login';
  static const String logout = '/delivery-boy/logout';
  static const String profile = '/delivery-boy/profile';

  // Dashboard & Shipments
  static const String dashboard = '/delivery-boy/dashboard';
  static const String shipments = '/delivery-boy/shipments';

  // Single Shipment Detail
  static String shipmentDetail(dynamic id) => '/delivery-boy/shipments/$id';

  // Status History
  static String statusHistory(dynamic id) => '/delivery-boy/shipments/$id/status-history';

  // Update Shipment Status (PATCH)
  static String updateShipmentStatus(dynamic id) => '/delivery-boy/shipments/$id/status';

  // Storage / Uploads Base URL
  static const String storageBaseUrl = 'https://jmdlogisticsolutions.com/storage';
  static String getStorageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$storageBaseUrl/$cleanPath';
  }
}
