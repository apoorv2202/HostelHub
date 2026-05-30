import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/user.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'auth/role_selection_screen.dart';

class CanteenDashboardScreen extends StatefulWidget {
  final UserModel user;

  const CanteenDashboardScreen({super.key, required this.user});

  @override
  State<CanteenDashboardScreen> createState() => _CanteenDashboardScreenState();
}

class _CanteenDashboardScreenState extends State<CanteenDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;
  String _filter = 'Active';
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
    // Fetch food items on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchFoodItems();
    });
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // Fetch orders scoped to Canteen Staff's College! (e.g. RVCE canteen only gets RVCE orders)
      final response = await _supabase
          .from('orders')
          .select('*, profiles(name, room_number, hostel)')
          .eq('college', widget.user.college)
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching canteen orders: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    switch (_filter) {
      case 'New':
        return _orders.where((o) => o['order_status'] == 'pending').toList();
      case 'Active':
        return _orders
            .where((o) =>
                o['order_status'] == 'accepted' ||
                o['order_status'] == 'preparing' ||
                o['order_status'] == 'ready')
            .toList();
      case 'Done':
        return _orders.where((o) => o['order_status'] == 'completed').toList();
      default:
        return _orders;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'order_status': newStatus})
          .eq('id', orderId);

      _showSnack('Order status updated to $newStatus ✓', AppTheme.statusCompleted);
      _fetchOrders();
    } catch (e) {
      _showSnack('Error updating order: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Canteen Dashboard'),
            Text(
              '${widget.user.college} Campus • Canteen Staff ${widget.user.name.split(' ').first}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGrey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _fetchOrders();
              } else {
                context.read<AppProvider>().fetchFoodItems();
              }
            },
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textGrey),
          ),
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textGrey),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Menu Management'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildMenuTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        _buildSummaryHeader(),
        _buildFilterRow(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredOrders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders in this category right now.',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    )
                  : _buildOrderList(),
        ),
      ],
    );
  }

  Widget _buildMenuTab() {
    final provider = context.watch<AppProvider>();
    final foodItems = provider.foodItems;

    if (foodItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: foodItems.length,
      itemBuilder: (context, index) {
        final item = foodItems[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Emoji thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: item.isVeg ? Colors.green : Colors.red,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: item.isVeg ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Stock Toggle Switch
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.isAvailable ? 'IN STOCK' : 'OUT STOCK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? AppTheme.statusCompleted : AppTheme.statusPending,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: item.isAvailable,
                      activeColor: AppTheme.primaryOrange,
                      onChanged: (_) {
                        provider.toggleFoodAvailability(item.id);
                        _showSnack(
                          '${item.name} is now ${!item.isAvailable ? "In Stock" : "Out of Stock"} ✓',
                          AppTheme.statusCompleted,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader() {
    final pending = _orders.where((o) => o['order_status'] == 'pending').length;
    final active = _orders
        .where((o) =>
            o['order_status'] == 'accepted' ||
            o['order_status'] == 'preparing' ||
            o['order_status'] == 'ready')
        .length;
    final completed = _orders.where((o) => o['order_status'] == 'completed').toList();
    final revenue = completed.fold<double>(
        0.0, (sum, o) => sum + (o['total_price'] as num).toDouble());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox('$pending', 'New', AppTheme.statusPending),
          _statBox('$active', 'Active', AppTheme.statusAccepted),
          _statBox('₹${revenue.toStringAsFixed(0)}', 'Earned', AppTheme.statusCompleted),
        ],
      ),
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = ['New', 'Active', 'Done', 'All'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppTheme.primaryOrange,
                    checkmarkColor: Colors.white,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    labelStyle: TextStyle(
                      color: _filter == f ? Colors.white : AppTheme.textGrey,
                      fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12,
                    ),
                    backgroundColor: AppTheme.surfaceDark,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildOrderList() {
    final list = _filteredOrders;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        final profile = order['profiles'] ?? {};
        final items = order['items'] as List;
        final status = order['order_status'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['id'].toString().substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      status.toString().toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Student: ${profile['name'] ?? "Unknown"}'),
                Text('Room: ${profile['room_number'] ?? "N/A"} · Hostel: ${profile['hostel'] ?? "N/A"}'),
                const Divider(),
                const SizedBox(height: 4),
                ...items.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i['name']} x ${i['quantity']}'),
                          Text('₹${i['price']}'),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '₹${order['total_price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButtons(order['id'].toString(), status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String id, String status) {
    if (status == 'pending') {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus(id, 'accepted'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusAccepted, foregroundColor: Colors.white),
        child: const Text('Accept Order'),
      );
    } else if (status == 'accepted') {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus(id, 'preparing'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange, foregroundColor: Colors.white),
        child: const Text('Start Cooking'),
      );
    } else if (status == 'preparing') {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus(id, 'ready'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
        child: const Text('Mark Ready'),
      );
    } else if (status == 'ready') {
      return ElevatedButton(
        onPressed: () => _updateOrderStatus(id, 'completed'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCompleted, foregroundColor: Colors.white),
        child: const Text('Complete & Deliver'),
      );
    }
    return const SizedBox.shrink();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        title: const Text('Logout', style: TextStyle(color: AppTheme.textWhite)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<AppProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
