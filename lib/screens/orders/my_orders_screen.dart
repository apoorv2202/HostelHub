// ─────────────────────────────────────────────
//  MyOrdersScreen — Past and current orders
// ─────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../services/night_canteen_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Auto-refresh every 15 seconds so status changes by canteen staff reflect here
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        context.read<AppProvider>().refreshOrders();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppProvider>().orders;
    final activeOrders = orders
        .where((o) =>
            o.status == OrderStatus.placed ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.outForDelivery)
        .toList();
    final pastOrders = orders
        .where((o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => context.read<AppProvider>().refreshOrders(),
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMedium),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${activeOrders.length})'),
            Tab(text: 'Past (${pastOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Active orders ──────────────────────────
          activeOrders.isEmpty
              ? EmptyState(
                  emoji: '🛵',
                  title: 'No active orders',
                  subtitle: 'Order something from the night canteen!',
                  action: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NightCanteenScreen()),
                    ),
                    icon: const Icon(Icons.restaurant_menu_rounded,
                        size: 16),
                    label: const Text('Browse Canteen'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: activeOrders.length,
                  itemBuilder: (_, i) =>
                      _OrderCard(order: activeOrders[i], isActive: true),
                ),

          // ── Past orders ────────────────────────────
          pastOrders.isEmpty
              ? const EmptyState(
                  emoji: '🧾',
                  title: 'No past orders',
                  subtitle:
                      'Your completed and cancelled orders will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: pastOrders.length,
                  itemBuilder: (_, i) =>
                      _OrderCard(order: pastOrders[i], isActive: false),
                ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isActive;

  const _OrderCard({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.cardBorder,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMedium,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                _statusChip(order.status),
              ],
            ),
          ),

          // ── Items ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}×',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Live tracker (for active orders) ──────
          if (isActive) ...[
            const SizedBox(height: 4),
            _buildLiveTracker(order.status),
          ],

          const Divider(height: 24),

          // ── Footer ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 14, color: AppTheme.textMedium),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textLight),
                    ),
                    Text(
                      '₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Reorder button ─────────────────────────
          if (!isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: GestureDetector(
                onTap: () {
                  // Reorder logic: add all items to cart
                  final cart = context.read<CartProvider>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Visit canteen to reorder these items 🍜'),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'Reorder',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Live order tracker ────────────────────
  Widget _buildLiveTracker(OrderStatus status) {
    final steps = [
      _TrackerStep(
        icon: Icons.check_circle_rounded,
        label: 'Order Placed',
        isDone: true,
      ),
      _TrackerStep(
        icon: Icons.local_fire_department_rounded,
        label: 'Preparing',
        isDone: status == OrderStatus.preparing ||
            status == OrderStatus.outForDelivery ||
            status == OrderStatus.delivered,
        isActive: status == OrderStatus.preparing,
      ),
      _TrackerStep(
        icon: Icons.delivery_dining_rounded,
        label: 'Out for Delivery',
        isDone: status == OrderStatus.outForDelivery ||
            status == OrderStatus.delivered,
        isActive: status == OrderStatus.outForDelivery,
      ),
      _TrackerStep(
        icon: Icons.home_rounded,
        label: 'Delivered',
        isDone: status == OrderStatus.delivered,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final step = e.value;
          final isLast = e.key == steps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: step.isDone
                            ? AppTheme.primary
                            : step.isActive
                                ? AppTheme.primaryLight
                                : AppTheme.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.isDone || step.isActive
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        size: 14,
                        color: step.isDone
                            ? Colors.white
                            : step.isActive
                                ? AppTheme.primary
                                : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: step.isDone || step.isActive
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        fontWeight: step.isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: step.isDone
                          ? AppTheme.primary
                          : AppTheme.cardBorder,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const StatusChip(
          label: 'Placed',
          bgColor: Color(0x26FFB020),
          textColor: Color(0xFFFFB020),
          icon: Icons.receipt_rounded,
        );
      case OrderStatus.preparing:
        return const StatusChip(
          label: 'Preparing 🔥',
          bgColor: Color(0x26FF6B35),
          textColor: Color(0xFFFF6B35),
          icon: Icons.local_fire_department_rounded,
        );
      case OrderStatus.outForDelivery:
        return const StatusChip(
          label: 'On the way 🛵',
          bgColor: Color(0x263B82F6),
          textColor: Color(0xFF3B82F6),
          icon: Icons.delivery_dining_rounded,
        );
      case OrderStatus.delivered:
        return StatusChip.completed();
      case OrderStatus.cancelled:
        return StatusChip.rejected();
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TrackerStep {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;

  const _TrackerStep({
    required this.icon,
    required this.label,
    this.isDone = false,
    this.isActive = false,
  });
}
