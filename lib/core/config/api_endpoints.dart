import 'app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Full base URL accessor from AppConfig
  static String get baseUrl => AppConfig.baseUrl;

  // --- Auth Endpoints ---
  static const String login = '/delivery-boy/login';
  static const String logout = '/delivery-boy/logout';
  static const String profile = '/delivery-boy/profile';

  // --- Delivery & Orders Endpoints ---
  static const String orders = '/delivery-boy/orders';
  static const String orderDetail = '/delivery-boy/orders/detail';
  static const String updateStatus = '/delivery-boy/orders/update-status';
  static const String submitPod = '/delivery-boy/orders/submit-pod';
  static const String verifyOtp = '/delivery-boy/orders/verify-otp';
}
