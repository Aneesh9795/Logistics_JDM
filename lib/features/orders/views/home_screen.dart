import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/order_model.dart';
import '../viewmodels/orders_viewmodel.dart';
import '../widgets/order_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final ordersVM = ref.read(ordersViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    final filteredList = ordersState.filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAsset,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'JMD',
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 20,
              width: 1,
              color: AppColors.divider,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  authState.partner?.id ?? 'DP-8801',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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
            icon: const Icon(Icons.logout, color: AppColors.textSecondary, size: 20),
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
            // Top Metrics Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Row
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

                    // Search Bar
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

            // Filter Chips Horizontal List
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChipItem(
                      label: 'All (${ordersState.totalCount})',
                      isSelected: ordersState.selectedFilter == null,
                      onTap: () => ordersVM.setFilter(null),
                    ),
                    _FilterChipItem(
                      label: 'New',
                      isSelected: ordersState.selectedFilter == OrderStatus.newOrder,
                      onTap: () => ordersVM.setFilter(OrderStatus.newOrder),
                    ),
                    _FilterChipItem(
                      label: 'Picked Up',
                      isSelected: ordersState.selectedFilter == OrderStatus.pickedUp,
                      onTap: () => ordersVM.setFilter(OrderStatus.pickedUp),
                    ),
                    _FilterChipItem(
                      label: 'In Transit',
                      isSelected: ordersState.selectedFilter == OrderStatus.inTransit,
                      onTap: () => ordersVM.setFilter(OrderStatus.inTransit),
                    ),
                    _FilterChipItem(
                      label: 'Delivered',
                      isSelected: ordersState.selectedFilter == OrderStatus.delivered,
                      onTap: () => ordersVM.setFilter(OrderStatus.delivered),
                    ),
                    _FilterChipItem(
                      label: 'Failed',
                      isSelected: ordersState.selectedFilter == OrderStatus.failed,
                      onTap: () => ordersVM.setFilter(OrderStatus.failed),
                    ),
                  ],
                ),
              ),
            ),

            // Section Label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Assigned Orders (${filteredList.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Tap View for details',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orders List
            if (filteredList.isEmpty)
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
                        'Try clearing search or filter',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = filteredList[index];
                    return OrderCard(
                      order: order,
                      onTapView: () {
                        context.push('/order-detail/${order.docketNo}');
                      },
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),

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

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryNavy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryNavy : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
