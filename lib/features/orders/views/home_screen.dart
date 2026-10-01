import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/order_model.dart';
import '../viewmodels/orders_viewmodel.dart';
import '../widgets/delivery_confirm_dialog.dart';
import '../widgets/failed_reason_sheet.dart';
import '../widgets/order_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final ordersVM = ref.read(ordersViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    final groupedOrders = ordersState.groupedOrdersByDate;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset(
                AppConstants.logoAsset,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'JMD',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 20,
              width: 1,
              color: Colors.white24,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.partner?.name ?? 'Delivery Partner',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  authState.partner?.id ?? 'DP-8801',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(200),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out from delivery session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(authViewModelProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: const Text('LOGOUT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            onRefresh: () => ordersVM.refresh(),
            color: AppColors.primaryNavy,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Metrics & Search Bar
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 4 Simple Counters
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Total',
                              count: ordersState.totalCount,
                              color: AppColors.primaryNavy,
                              icon: Icons.inventory_2_outlined,
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Pending',
                              count: ordersState.pendingCount,
                              color: AppColors.statusInTransitText,
                              icon: Icons.local_shipping_outlined,
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Delivered',
                              count: ordersState.deliveredCount,
                              color: AppColors.statusDeliveredText,
                              icon: Icons.check_circle_outline,
                            ),
                            const SizedBox(width: 8),
                            _MetricCard(
                              title: 'Failed',
                              count: ordersState.failedCount,
                              color: AppColors.statusFailedText,
                              icon: Icons.highlight_off_rounded,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Fast Search Bar
                        TextField(
                          onChanged: (val) => ordersVM.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search by Docket, Brand, From or To...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.scaffoldBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),

                // Empty State
                if (ordersState.filteredOrders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching with a different Docket or Location',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Date-wise Grouped Orders (Boss's exact sketch)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dateEntry = groupedOrders.entries.elementAt(index);
                        final dateKey = dateEntry.key;
                        final ordersInDate = dateEntry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header Section (e.g. "📅 DATE: 01-08-2026 (16 Orders)")
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryNavy,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'DATE: $dateKey',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(50),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${ordersInDate.length} Orders',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Clean Cards for this Date
                              ...ordersInDate.map((order) {
                                return OrderCard(
                                  order: order,
                                  onTapView: () {
                                    context.push('/order-detail/${order.docketNo}');
                                  },
                                  onStatusChanged: (newStatus) {
                                    if (newStatus == OrderStatus.delivered) {
                                      DeliveryHelper.startDeliveryFlow(
                                        context: context,
                                        docketNo: order.docketNo,
                                        onConfirmed: (imagePath) {
                                          ordersVM.markAsDelivered(order.docketNo, imagePath);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Delivery proof uploaded! Order marked as Delivered.'),
                                              backgroundColor: AppColors.statusDeliveredText,
                                            ),
                                          );
                                        },
                                      );
                                    } else if (newStatus == OrderStatus.failed) {
                                      FailedReasonSheet.show(context, (reason) {
                                        ordersVM.markAsFailed(order.docketNo, reason);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Order marked as Failed.'),
                                            backgroundColor: AppColors.brandRed,
                                          ),
                                        );
                                      });
                                    } else {
                                      ordersVM.updateOrderStatus(order.docketNo, newStatus);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Status updated to: ${newStatus.label}'),
                                          duration: const Duration(milliseconds: 1200),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      },
                      childCount: groupedOrders.length,
                    ),
                  ),

                // Bottom safe space for physical / on-screen navbars
                const SliverToBoxAdapter(
                  child: SafeArea(
                    top: false,
                    minimum: EdgeInsets.only(bottom: 24),
                    child: SizedBox(height: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
