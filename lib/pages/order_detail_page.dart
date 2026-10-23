import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/config/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/ui_helpers.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import 'widgets/delivery_confirm_dialog.dart';
import 'widgets/failed_reason_sheet.dart';
import 'widgets/status_badge.dart';

class OrderDetailPage extends ConsumerWidget {
  final String docketNo;

  const OrderDetailPage({
    super.key,
    required this.docketNo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(singleOrderProvider(docketNo));
    final ordersVM = ref.read(ordersProvider.notifier);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    final isDelivered = order.status == OrderStatus.delivered;
    final isFailed = order.status == OrderStatus.failed;
    final cachedLocalPod = ref.watch(tokenStorageProvider).getLocalPodPath(docketNo);
    final effectiveProof = (order.invoiceImagePath != null && order.invoiceImagePath!.isNotEmpty)
        ? order.invoiceImagePath!
        : (cachedLocalPod ?? '');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Docket: ${order.docketNo}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(status: order.status, isLarge: true),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Alert Banner (if Delivered or Failed)
                if (isDelivered) ...[
                  _buildDeliveredBanner(order),
                  const SizedBox(height: 16),
                ] else if (isFailed) ...[
                  _buildFailedBanner(order),
                  const SizedBox(height: 16),
                ],

                // Card 1: Order Core Information
                _buildOrderInfoCard(order),

                const SizedBox(height: 16),

                // Card 2: Pickup & Delivery Route
                _buildRouteCard(order),

                const SizedBox(height: 16),

                // Card 3: Invoice Proof Display (If available / Delivered)
                if (effectiveProof.isNotEmpty) ...[
                  _buildInvoiceProofCard(context, ref, order, effectiveProof),
                  const SizedBox(height: 16),
                ],

                // Card 4: Failure Reason Display (If available / Failed)
                if (order.failedReason != null && order.failedReason!.isNotEmpty) ...[
                  _buildFailureReasonCard(order.failedReason!),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),

      // Fixed Bottom Actions: [ DELIVERY ] & [ FAILED ]
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          // 34dp minimum bottom clearance so buttons float well above physical/virtual navbars
          minimum: const EdgeInsets.only(bottom: 34),
          child: Align(
            heightFactor: 1.0,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // FAILED Action Button
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.brandRed, width: 1.8),
                            foregroundColor: AppColors.brandRed,
                            backgroundColor: isFailed ? AppColors.statusFailedBg : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          label: Text(
                            isFailed ? 'FAILED (EDIT)' : 'FAILED',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          onPressed: () {
                            FailedReasonSheet.show(context, (reason) async {
                              _showLoadingDialog(context, 'Updating order status...');
                              final result = await ordersVM.markOrderFailed(order.docketNo, reason);
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
                                if (result.success) {
                                  AppSnackbar.showSuccess(context, 'Order marked as Failed.');
                                } else {
                                  AppSnackbar.showError(context, result.error ?? 'Failed to update status on server.');
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // DELIVERY Action Button
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusDeliveredText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                          label: Text(
                            isDelivered ? 'DELIVERED (OK)' : 'DELIVERY',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: () {
                            DeliveryHelper.startDeliveryFlow(
                              context: context,
                              docketNo: order.docketNo,
                              onConfirmed: (imagePath) async {
                                _showLoadingDialog(context, 'Uploading delivery proof & updating status...');
                                final result = await ordersVM.markOrderDelivered(
                                  order.docketNo,
                                  invoiceImagePath: imagePath,
                                );
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
                                  if (result.success) {
                                    AppSnackbar.showSuccess(context, 'Delivery proof uploaded! Order marked as Delivered.');
                                  } else {
                                    AppSnackbar.showError(context, result.error ?? 'Upload failed on server.');
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveredBanner(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusDeliveredBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusDeliveredBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.statusDeliveredText, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Delivered Successfully',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusDeliveredText,
                  ),
                ),
                if (order.completedAt != null)
                  Text(
                    'Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.completedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusFailedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusFailedBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusFailedText, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Failed',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusFailedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.failedReason ?? 'No reason recorded',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER SPECIFICATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),

            _buildDetailRow('S. No.', '${order.sNo}'),
            _buildDetailRow('Docket No.', order.docketNo, isBold: true),
            _buildDetailRow('Brand', order.brand, isTag: true),
            if (order.customerCompany.isNotEmpty && order.customerCompany != order.brand)
              _buildDetailRow('Company Name', order.customerCompany),
            if (order.customerName.isNotEmpty)
              _buildDetailRow('Customer Name', order.customerName),
            _buildDetailRow('No. of Boxes', order.noOfBoxes),
            _buildDetailRow('Booking Date', order.orderDate),
            _buildDetailRow('Delivery Date', order.deliveryDate, highlight: true),
            _buildDetailRow('Current Status', order.status.label),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DISPATCH & DESTINATION ROUTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),

            // Pickup Origin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.primaryNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup From (Origin)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.from,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
              child: Container(
                width: 2,
                height: 28,
                color: AppColors.divider,
              ),
            ),

            // Drop Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.brandRed),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deliver To (Destination)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.to,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceProofCard(BuildContext context, WidgetRef ref, OrderModel order, String imagePath) {
    Widget imageWidget;
    final isLocal = !kIsWeb && File(imagePath).existsSync();
    final localFallback = ref.watch(tokenStorageProvider).getLocalPodPath(order.docketNo);
    final hasLocalFallback = localFallback != null && !kIsWeb && File(localFallback).existsSync();

    if (isLocal) {
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    } else {
      final fullUrl = ApiEndpoints.getStorageUrl(imagePath);

      imageWidget = Image.network(
        fullUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (hasLocalFallback) {
            return Image.file(
              File(localFallback),
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(
                label: 'Proof recorded on server',
              ),
            );
          }
          return _buildImagePlaceholder(
            label: 'Proof recorded on server',
          );
        },
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVOICE / PAYMENT PROOF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                Icon(Icons.verified, size: 18, color: AppColors.statusDeliveredText),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 220,
                color: Colors.grey.shade100,
                child: imageWidget,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Proof captured and verified by delivery partner',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({String label = 'Image unavailable'}) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureReasonCard(String reason) {
    return Card(
      color: AppColors.statusFailedBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem_outlined, size: 18, color: AppColors.statusFailedText),
                SizedBox(width: 8),
                Text(
                  'REASON FOR FAILED DELIVERY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusFailedText,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isTag = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isTag
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandRed,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isBold ? FontWeight.w800 : (highlight ? FontWeight.w700 : FontWeight.w600),
                        color: highlight ? AppColors.primaryNavy : AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
