import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum OrderStatus {
  newOrder,
  pickedUp,
  inTransit,
  delivered,
  failed;

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'Booked';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.failed:
        return 'Failed';
    }
  }

  Color get textColor {
    switch (this) {
      case OrderStatus.newOrder:
        return AppColors.statusNewText;
      case OrderStatus.pickedUp:
        return AppColors.statusPickedUpText;
      case OrderStatus.inTransit:
        return AppColors.statusInTransitText;
      case OrderStatus.delivered:
        return AppColors.statusDeliveredText;
      case OrderStatus.failed:
        return AppColors.statusFailedText;
    }
  }

  Color get bgColor {
    switch (this) {
      case OrderStatus.newOrder:
        return AppColors.statusNewBg;
      case OrderStatus.pickedUp:
        return AppColors.statusPickedUpBg;
      case OrderStatus.inTransit:
        return AppColors.statusInTransitBg;
      case OrderStatus.delivered:
        return AppColors.statusDeliveredBg;
      case OrderStatus.failed:
        return AppColors.statusFailedBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case OrderStatus.newOrder:
        return AppColors.statusNewBorder;
      case OrderStatus.pickedUp:
        return AppColors.statusPickedUpBorder;
      case OrderStatus.inTransit:
        return AppColors.statusInTransitBorder;
      case OrderStatus.delivered:
        return AppColors.statusDeliveredBorder;
      case OrderStatus.failed:
        return AppColors.statusFailedBorder;
    }
  }

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.newOrder;
    final lower = val.toLowerCase().trim();
    if (lower == 'delivered') return OrderStatus.delivered;
    if (lower == 'failed') return OrderStatus.failed;
    if (lower == 'in transit' || lower == 'intransit') return OrderStatus.inTransit;
    if (lower == 'picked up' || lower == 'pickedup') return OrderStatus.pickedUp;
    return OrderStatus.newOrder;
  }
}

class OrderModel {
  final int id;
  final String docketNo;
  final String pickupLocation;
  final String deliveryLocation;
  final String pickupDate;
  final String expectedDeliveryDate;
  final String deliveryDateStr;
  final String consigneeName;
  final String consigneeContact;
  final String weight;
  final String pieces;
  final String brandName;
  final String description;
  final OrderStatus status;
  final String currentLocation;
  final String? remarks;
  final String? podFile;
  final String customerName;
  final String customerCompany;
  final String customerMobile;
  final String fullDeliveryAddress;
  final String? failedReason;
  final DateTime? completedAt;

  const OrderModel({
    required this.id,
    required this.docketNo,
    required this.pickupLocation,
    required this.deliveryLocation,
    this.pickupDate = '',
    this.expectedDeliveryDate = '',
    this.deliveryDateStr = '',
    this.consigneeName = '',
    this.consigneeContact = '',
    this.weight = '0.00',
    this.pieces = '1',
    this.brandName = '',
    this.description = '',
    this.status = OrderStatus.newOrder,
    this.currentLocation = '',
    this.remarks,
    this.podFile,
    this.customerName = '',
    this.customerCompany = '',
    this.customerMobile = '',
    this.fullDeliveryAddress = '',
    this.failedReason,
    this.completedAt,
  });

  // UI Compatibility Getters
  int get sNo => id;
  String get from => pickupLocation.isNotEmpty ? pickupLocation : 'Main Hub';
  String get to => deliveryLocation.isNotEmpty ? deliveryLocation : fullDeliveryAddress;
  String get brand => brandName.isNotEmpty ? brandName : (customerCompany.isNotEmpty ? customerCompany : 'JMD');
  String get noOfBoxes => '$pieces Box';
  String get orderDate => pickupDate.split('T').first;
  String get deliveryDate => expectedDeliveryDate.isNotEmpty ? expectedDeliveryDate.split('T').first : deliveryDateStr.split('T').first;
  String? get invoiceImagePath => podFile;

  OrderModel copyWith({
    int? id,
    String? docketNo,
    String? pickupLocation,
    String? deliveryLocation,
    String? pickupDate,
    String? expectedDeliveryDate,
    String? deliveryDateStr,
    String? consigneeName,
    String? consigneeContact,
    String? weight,
    String? pieces,
    String? brandName,
    String? description,
    OrderStatus? status,
    String? currentLocation,
    String? remarks,
    String? podFile,
    String? customerName,
    String? customerCompany,
    String? customerMobile,
    String? fullDeliveryAddress,
    String? failedReason,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      docketNo: docketNo ?? this.docketNo,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryDateStr: deliveryDateStr ?? this.deliveryDateStr,
      consigneeName: consigneeName ?? this.consigneeName,
      consigneeContact: consigneeContact ?? this.consigneeContact,
      weight: weight ?? this.weight,
      pieces: pieces ?? this.pieces,
      brandName: brandName ?? this.brandName,
      description: description ?? this.description,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      remarks: remarks ?? this.remarks,
      podFile: podFile ?? this.podFile,
      customerName: customerName ?? this.customerName,
      customerCompany: customerCompany ?? this.customerCompany,
      customerMobile: customerMobile ?? this.customerMobile,
      fullDeliveryAddress: fullDeliveryAddress ?? this.fullDeliveryAddress,
      failedReason: failedReason ?? this.failedReason,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;
    final addressData = json['delivery_address'] as Map<String, dynamic>?;

    final id = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? json['s_no']?.toString() ?? '0') ?? 0);

    return OrderModel(
      id: id,
      docketNo: (json['docket_no'] ?? json['docketNo'] ?? '').toString(),
      pickupLocation: (json['pickup_location'] ?? json['from'] ?? '').toString().trim(),
      deliveryLocation: (json['delivery_location'] ?? json['to'] ?? '').toString().trim(),
      pickupDate: (json['pickup_date'] ?? json['date'] ?? '').toString(),
      expectedDeliveryDate: (json['expected_delivery_date'] ?? json['delivery_date'] ?? '').toString(),
      deliveryDateStr: (json['delivery_date'] ?? '').toString(),
      consigneeName: (json['consignee_name'] ?? '').toString(),
      consigneeContact: (json['consignee_contact'] ?? '').toString(),
      weight: (json['weight'] ?? '0.00').toString(),
      pieces: (json['pieces'] ?? json['no_of_boxes']?.toString().replaceAll('Box', '').trim() ?? '1').toString(),
      brandName: (json['brand_name'] ?? json['brand'] ?? '').toString().trim(),
      description: (json['description'] ?? json['item_description'] ?? json['product_description'] ?? '').toString().trim(),
      status: OrderStatus.fromString(json['status'] as String?),
      currentLocation: (json['current_location'] ?? '').toString(),
      remarks: (json['remarks'] ?? json['remark'] ?? json['instructions'] ?? json['notes'])?.toString().trim(),
      podFile: () {
        final raw = json['pod_file'] ??
            json['pod_url'] ??
            json['pod_file_url'] ??
            json['pod_image'] ??
            json['pod_image_url'] ??
            json['pod_path'] ??
            json['pod'] ??
            json['proof_of_delivery'] ??
            json['invoice_image_path'] ??
            json['invoice_image'] ??
            json['invoice_file'] ??
            json['invoice_url'] ??
            json['invoice'];
        if (raw == null) return null;
        if (raw is String) return raw.trim().isNotEmpty ? raw.trim() : null;
        if (raw is Map) {
          final url = raw['url'] ?? raw['path'] ?? raw['file'];
          return url?.toString();
        }
        return raw.toString();
      }(),
      customerName: customerData?['customer_name'] as String? ?? '',
      customerCompany: customerData?['company_name'] as String? ?? '',
      customerMobile: customerData?['mobile'] as String? ?? '',
      fullDeliveryAddress: addressData?['address'] as String? ?? '',
      failedReason: json['failed_reason'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docket_no': docketNo,
      'pickup_location': pickupLocation,
      'delivery_location': deliveryLocation,
      'pickup_date': pickupDate,
      'expected_delivery_date': expectedDeliveryDate,
      'delivery_date': deliveryDateStr,
      'consignee_name': consigneeName,
      'consignee_contact': consigneeContact,
      'weight': weight,
      'pieces': pieces,
      'brand': brandName,
      'description': description,
      'status': status.label,
      'current_location': currentLocation,
      'remarks': remarks,
      'pod_file': podFile,
      'customer': {
        'customer_name': customerName,
        'company_name': customerCompany,
        'mobile': customerMobile,
      },
      'delivery_address': {
        'address': fullDeliveryAddress,
      },
    };
  }
}
