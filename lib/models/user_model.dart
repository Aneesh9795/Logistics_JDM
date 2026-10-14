class UserModel {
  final String id;
  final String name;
  final String mobile;
  final bool status;
  final String hubName;

  const UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.status = true,
    this.hubName = 'Main Hub',
  });

  // Helper getters for convenience
  String get username => mobile;
  String get phone => mobile;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String? ?? '').trim(),
      mobile: (json['mobile'] ?? json['phone'] ?? '').toString().trim(),
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
