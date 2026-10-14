class PartnerModel {
  final String id;
  final String name;
  final String mobile;
  final bool status;
  final String hubName;

  const PartnerModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.status = true,
    this.hubName = 'Main Hub',
  });

  // Backward compatible getters
  String get username => mobile;
  String get phone => mobile;

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String? ?? '').trim(),
      mobile: (json['mobile'] ?? json['phone'] ?? json['username'] ?? '').toString().trim(),
      status: json['status'] is bool
          ? json['status'] as bool
          : (json['status'] == 1 || json['status'] == '1'),
      hubName: json['hub_name'] as String? ?? 'Main Hub',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'status': status,
      'hub_name': hubName,
    };
  }
}
