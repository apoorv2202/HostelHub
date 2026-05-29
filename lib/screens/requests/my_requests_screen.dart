// ─────────────────────────────────────────────
//  MyRequestsScreen — All submitted requests
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../services/room_services_screen.dart';
import '../services/maintenance_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allRequests = provider.requests;
    final cleaningReqs = provider.cleaningRequests;
    final maintenanceReqs = provider.maintenanceRequests;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('My Requests'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'All (${allRequests.length})'),
            Tab(text: 'Cleaning (${cleaningReqs.length})'),
            Tab(text: 'Maintenance (${maintenanceReqs.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RequestsList(
            requests: allRequests,
            emptyTitle: 'No requests yet',
            emptySubtitle: 'Submit a cleaning or maintenance request to get started',
            emptyEmoji: '📋',
          ),
          _RequestsList(
            requests: cleaningReqs,
            emptyTitle: 'No cleaning requests',
            emptySubtitle: 'Tap below to request a room cleaning',
            emptyEmoji: '🧹',
            emptyAction: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RoomServicesScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Request Cleaning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
          _RequestsList(
            requests: maintenanceReqs,
            emptyTitle: 'No maintenance requests',
            emptySubtitle: 'Report an issue and our team will fix it',
            emptyEmoji: '🔧',
            emptyAction: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Report Issue'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRequestSheet(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showAddRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'What do you need help with?',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 24),
            _SheetOption(
              emoji: '🧹',
              title: 'Room Cleaning',
              subtitle: 'Normal or deep cleaning',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoomServicesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _SheetOption(
              emoji: '🔧',
              title: 'Maintenance',
              subtitle: 'Electrical, furniture, etc.',
              color: AppTheme.success,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MaintenanceScreen()),
                );
              },
            ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}

// ── Request list with empty state ─────────
class _RequestsList extends StatelessWidget {
  final List<RequestModel> requests;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyEmoji;
  final Widget? emptyAction;

  const _RequestsList({
    required this.requests,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyEmoji,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        emoji: emptyEmoji,
        title: emptyTitle,
        subtitle: emptySubtitle,
        action: emptyAction,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(request: requests[i]),
    );
  }
}

// ── Request Card ──────────────────────────
class _RequestCard extends StatelessWidget {
  final RequestModel request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: request.type == RequestType.cleaning
                        ? AppTheme.primaryLight
                        : AppTheme.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      request.type == RequestType.cleaning ? '🧹' : '🔧',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            request.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          _buildStatusChip(request.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // ── Footer ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Request ID
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Category tag
                if (request.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.category!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                // Date
                Icon(Icons.schedule_rounded,
                    size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar for in-progress ──────────
          if (request.status == RequestStatus.inProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff on their way...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: const Color(0xFFEFF6FF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6)),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return StatusChip.pending();
      case RequestStatus.inProgress:
        return StatusChip.inProgress();
      case RequestStatus.completed:
        return StatusChip.completed();
      case RequestStatus.rejected:
        return StatusChip.rejected();
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Bottom sheet option ───────────────────
class _SheetOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
