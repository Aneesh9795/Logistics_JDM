import 'partner_model.dart';

class LoginResponse {
  final bool success;
  final String message;
  final String token;
  final PartnerModel deliveryBoy;

  const LoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.deliveryBoy,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Login successful.',
      token: json['token'] as String? ?? '',
      deliveryBoy: PartnerModel.fromJson(
        json['delivery_boy'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
