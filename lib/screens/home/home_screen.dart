// ─────────────────────────────────────────────
//  HomeScreen — Dashboard with service tiles
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/cart_provider.dart';
import '../services/room_services_screen.dart';
import '../services/night_canteen_screen.dart';
import '../services/maintenance_screen.dart';
import '../services/lost_items_screen.dart';
import '../services/cart_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Sticky App Bar ─────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, user, cartCount),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: AppTheme.divider,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Welcome card ───────────────────────────
                _buildWelcomeCard(user?.name ?? 'Student'),

                const SizedBox(height: 28),

                // ── Quick Stats ────────────────────────────
                _buildQuickStats(context),

                const SizedBox(height: 28),

                // ── Services grid ──────────────────────────
                const _SectionTitle(
                  title: 'Our Services',
                  subtitle: 'Everything you need',
                ),
                const SizedBox(height: 16),
                _buildServicesGrid(context),

                const SizedBox(height: 28),

                // ── Announcements ──────────────────────────
                const _SectionTitle(title: 'Announcements 📢'),
                const SizedBox(height: 16),
                _buildAnnouncements(),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top header ────────────────────────────
  Widget _buildHeader(BuildContext context, user, int cartCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_getGreeting()}, ${user?.name.split(' ').first ?? 'Student'} 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        size: 13, color: AppTheme.textMedium),
                    const SizedBox(width: 4),
                    Text(
                      user != null
                          ? '${user.hostel} · Room ${user.roomNumber}'
                          : 'Set up your profile',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cart badge
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppTheme.primary, size: 22),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome streak card ───────────────────
  Widget _buildWelcomeCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B5FEF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏠 Your Home Away From Home',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Need anything?\nWe\'ve got you covered!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🌙 Night canteen open till 2 AM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text('🏡', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }

  // ── Quick stats row ───────────────────────
  Widget _buildQuickStats(BuildContext context) {
    final requests = context.watch<AppProvider>().requests;
    final pending = requests.where((r) =>
        r.status.name == 'pending' || r.status.name == 'inProgress').length;

    return Row(
      children: [
        _StatTile(value: '$pending', label: 'Active\nRequests', icon: '⏳'),
        const SizedBox(width: 12),
        _StatTile(
            value:
                '${context.watch<CartProvider>().itemCount}',
            label: 'Cart\nItems',
            icon: '🛒'),
        const SizedBox(width: 12),
        _StatTile(
            value: '24/7',
            label: 'Support\nAvailable',
            icon: '💬'),
      ],
    );
  }

  // ── Services grid ─────────────────────────
  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      _ServiceData(
        emoji: '🧹',
        title: 'Room\nServices',
        subtitle: 'Cleaning & More',
        color: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoomServicesScreen()),
        ),
      ),
      _ServiceData(
        emoji: '🍜',
        title: 'Night\nCanteen',
        subtitle: 'Open 8PM–2AM',
        color: const Color(0xFFFF6B35),
        bgColor: const Color(0xFFFFF0EB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NightCanteenScreen()),
        ),
      ),
      _ServiceData(
        emoji: '🔧',
        title: 'Maintenance',
        subtitle: 'Report Issues',
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
        ),
      ),
      _ServiceData(
        emoji: '🔑',
        title: 'Lost\nItems',
        subtitle: 'Report & Pay',
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LostItemsScreen()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: services.map((s) => _ServiceCard(data: s)).toList(),
    );
  }

  // ── Announcements ─────────────────────────
  Widget _buildAnnouncements() {
    final items = [
      ('📢', 'Mess timing changed to 7:30 AM – 9:30 AM from Monday',
          '2 hours ago'),
      ('🛠️', 'Scheduled maintenance on Block C lifts this Saturday',
          'Yesterday'),
      ('🎉', 'Night Canteen menu updated! Try new Momos & Rolls',
          '2 days ago'),
    ];

    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

// ── Section Title ─────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
          ),
      ],
    );
  }
}

// ── Stat tile ─────────────────────────────
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMedium,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Card ──────────────────────────
class _ServiceData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  _ServiceData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData data;

  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.color.withOpacity(0.15),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const Spacer(),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: data.color,
                height: 1.2,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: data.color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
