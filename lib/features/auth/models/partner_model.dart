class PartnerModel {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String hubName;

  const PartnerModel({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.hubName,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hubName: json['hub_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'hub_name': hubName,
    };
  }
}
