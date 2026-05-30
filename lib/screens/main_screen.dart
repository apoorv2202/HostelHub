import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/request.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  final AppUser user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _StudentHomeTab(user: widget.user),
      _StudentRequestsTab(user: widget.user),
      _StudentOrdersTab(user: widget.user),
      _StudentProfileTab(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.surfaceBlack,
        indicatorColor: AppTheme.primaryOrange.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryOrange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.primaryOrange),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryOrange),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryOrange),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────
class _StudentHomeTab extends StatelessWidget {
  final AppUser user;
  const _StudentHomeTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Hub'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.name[0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(context),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            Text('Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 12),
            ...MockRequestData.requests.take(3).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityCard(request: r),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryOrange, AppTheme.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting,',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14)),
          Text(
            user.name.split(' ').first,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.meeting_room_rounded, user.roomNumber ?? 'N/A'),
              const SizedBox(width: 8),
              _infoChip(Icons.school_rounded, user.department ?? 'CSE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': '🧹', 'label': 'Cleaning'},
      {'icon': '🔧', 'label': 'Maintenance'},
      {'icon': '🍽️', 'label': 'Food Order'},
      {'icon': '🔍', 'label': 'Lost Item'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            return GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${actions[i]['label']} request submitted!'),
                  backgroundColor: AppTheme.primaryOrange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.dividerBlack),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(actions[i]['icon']!,
                        style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      actions[i]['label']!,
                      style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final HostelRequest request;
  const _ActivityCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(request.type.icon,
                style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(request.type.label,
            style: const TextStyle(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        subtitle: Text(request.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
        trailing: RequestStatusChip(status: request.status),
      ),
    );
  }
}

// ── Requests Tab ─────────────────────────────────────────────
class _StudentRequestsTab extends StatelessWidget {
  final AppUser user;
  const _StudentRequestsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: MockRequestData.requests.isEmpty
          ? const EmptyState(
              emoji: '📋',
              title: 'No requests yet',
              subtitle: 'Submit a new request from the Home tab',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: MockRequestData.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = MockRequestData.requests[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.type.icon,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(r.type.label,
                                  style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontWeight: FontWeight.w600)),
                            ),
                            RequestStatusChip(status: r.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.description,
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Orders Tab ───────────────────────────────────────────────
class _StudentOrdersTab extends StatelessWidget {
  final AppUser user;
  const _StudentOrdersTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: MockOrderData.orders.isEmpty
          ? const EmptyState(
              emoji: '🍽️',
              title: 'No orders yet',
              subtitle: 'Place a food order from the Home tab',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: MockOrderData.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = MockOrderData.orders[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🧾',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Text(o.id,
                                style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            OrderStatusChip(status: o.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...o.items.map((item) => Text(
                              '${item.quantity}× ${item.name}',
                              style: const TextStyle(
                                  color: AppTheme.textGrey, fontSize: 13),
                            )),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ₹${o.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Profile Tab ──────────────────────────────────────────────
class _StudentProfileTab extends StatelessWidget {
  final AppUser user;
  const _StudentProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(user.name[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user.role.label,
                style: const TextStyle(
                    color: AppTheme.primaryOrange, fontSize: 13)),
            const SizedBox(height: 24),
            _tile(Icons.meeting_room_rounded, 'Room Number',
                user.roomNumber ?? 'N/A'),
            _tile(Icons.school_rounded, 'Department', user.department ?? 'N/A'),
            _tile(Icons.phone_rounded, 'Phone', '+91 ${user.phone}'),
            _tile(Icons.badge_rounded, 'Student ID', user.id),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBlack,
                foregroundColor: AppTheme.textGrey,
                side: const BorderSide(color: AppTheme.dividerBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryOrange, size: 20),
        title: Text(label,
            style: const TextStyle(
                color: AppTheme.textGrey, fontSize: 12)),
        subtitle: Text(value,
            style: const TextStyle(
                color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
