import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OrderStatus {
  newOrder,
  pickedUp,
  inTransit,
  delivered,
  failed;

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'New';
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
  final int sNo; // Column A only
  final String deliveryDate; // Column B
  final String orderDate; // Column D
  final String docketNo; // Column E
  final String from; // Column F
  final String to; // Column G
  final String brand; // Column H
  final String noOfBoxes; // Column I
  final OrderStatus status;
  final String? invoiceImagePath;
  final String? failedReason;
  final DateTime? completedAt;

  const OrderModel({
    required this.sNo,
    required this.deliveryDate,
    required this.orderDate,
    required this.docketNo,
    required this.from,
    required this.to,
    required this.brand,
    required this.noOfBoxes,
    this.status = OrderStatus.newOrder,
    this.invoiceImagePath,
    this.failedReason,
    this.completedAt,
  });

  OrderModel copyWith({
    int? sNo,
    String? deliveryDate,
    String? orderDate,
    String? docketNo,
    String? from,
    String? to,
    String? brand,
    String? noOfBoxes,
    OrderStatus? status,
    String? invoiceImagePath,
    String? failedReason,
    DateTime? completedAt,
  }) {
    return OrderModel(
      sNo: sNo ?? this.sNo,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      orderDate: orderDate ?? this.orderDate,
      docketNo: docketNo ?? this.docketNo,
      from: from ?? this.from,
      to: to ?? this.to,
      brand: brand ?? this.brand,
      noOfBoxes: noOfBoxes ?? this.noOfBoxes,
      status: status ?? this.status,
      invoiceImagePath: invoiceImagePath ?? this.invoiceImagePath,
      failedReason: failedReason ?? this.failedReason,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      sNo: json['s_no'] is int
          ? json['s_no'] as int
          : int.tryParse(json['s_no']?.toString() ?? '0') ?? 0,
      deliveryDate: json['delivery_date'] as String? ?? '',
      orderDate: json['date'] as String? ?? '',
      docketNo: json['docket_no'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      noOfBoxes: json['no_of_boxes'] as String? ?? '1 Box',
      status: OrderStatus.fromString(json['status'] as String?),
      invoiceImagePath: json['invoice_image_path'] as String?,
      failedReason: json['failed_reason'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      's_no': sNo,
      'delivery_date': deliveryDate,
      'date': orderDate,
      'docket_no': docketNo,
      'from': from,
      'to': to,
      'brand': brand,
      'no_of_boxes': noOfBoxes,
      'status': status.label,
      'invoice_image_path': invoiceImagePath,
      'failed_reason': failedReason,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
