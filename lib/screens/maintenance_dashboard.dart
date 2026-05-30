import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'auth/role_selection_screen.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  final UserModel user;

  const MaintenanceDashboardScreen({super.key, required this.user});

  @override
  State<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends State<MaintenanceDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _filter = 'All';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchMaintenanceRequests();
  }

  Future<void> _fetchMaintenanceRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('maintenance_requests')
          .select('*, profiles(name, room_number, hostel, college)')
          .order('created_at', ascending: false);

      // Scoping maintenance requests by staff college campus! (e.g. RVCE only gets RVCE maintenance)
      final List<Map<String, dynamic>> scopedRequests = [];
      for (var r in response as List) {
        final profile = r['profiles'];
        if (profile != null && profile['college'] == widget.user.college) {
          scopedRequests.add(r as Map<String, dynamic>);
        }
      }

      setState(() {
        _requests = scopedRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching maintenance requests: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    switch (_filter) {
      case 'Pending':
        return _requests.where((r) => r['status'] == 'pending').toList();
      case 'Active':
        return _requests.where((r) => r['status'] == 'accepted').toList();
      case 'Done':
        return _requests.where((r) => r['status'] == 'completed').toList();
      default:
        return _requests;
    }
  }

  Future<void> _updateRequestStatus(String reqId, String newStatus) async {
    try {
      await _supabase
          .from('maintenance_requests')
          .update({'status': newStatus})
          .eq('id', reqId);

      _showSnack('Request status updated to $newStatus ✓', AppTheme.statusCompleted);
      _fetchMaintenanceRequests();
    } catch (e) {
      _showSnack('Error updating request: $e', Colors.red);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance Portal'),
            Text(
              '${widget.user.college} Campus • Staff ${widget.user.name.split(' ').first}',
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
            onPressed: _fetchMaintenanceRequests,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textGrey),
          ),
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textGrey),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          _buildFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? const Center(
                        child: Text(
                          'No maintenance issues reported.',
                          style: TextStyle(color: AppTheme.textGrey),
                        ),
                      )
                    : _buildRequestList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final pending = _requests.where((r) => r['status'] == 'pending').length;
    final active = _requests.where((r) => r['status'] == 'accepted').length;
    final completed = _requests.where((r) => r['status'] == 'completed').length;

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
          _statBox('$pending', 'New Issues', AppTheme.statusPending),
          _statBox('$active', 'In Progress', AppTheme.statusAccepted),
          _statBox('$completed', 'Resolved', AppTheme.statusCompleted),
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
    final filters = ['All', 'Pending', 'Active', 'Done'];
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

  Widget _buildRequestList() {
    final list = _filteredRequests;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final req = list[index];
        final profile = req['profiles'] ?? {};
        final status = req['status'];
        final images = req['image_urls'] as List?;

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
                      '${req['category'] != null ? req['category'][0].toUpperCase() + req['category'].substring(1) : "Maintenance"} Issue 🔧',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? AppTheme.statusCompleted.withOpacity(0.12)
                            : (status == 'accepted' ? AppTheme.statusAccepted.withOpacity(0.12) : AppTheme.statusPending.withOpacity(0.12)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'completed'
                              ? AppTheme.statusCompleted
                              : (status == 'accepted' ? AppTheme.statusAccepted : AppTheme.statusPending),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Student: ${profile['name'] ?? "Unknown"}'),
                Text('Room: ${profile['room_number'] ?? "N/A"} · Hostel: ${profile['hostel'] ?? "N/A"}'),
                const Divider(),
                const SizedBox(height: 4),
                const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  req['description'] ?? 'No description provided.',
                  style: const TextStyle(color: AppTheme.textGrey, height: 1.3),
                ),
                if (images != null && images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Attached Pictures:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, idx) {
                        final category = req['category']?.toString().toLowerCase() ?? 'electrician';

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: category == 'furniture'
                                ? const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFF78350F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category == 'furniture' ? '🪑 Furniture' : '⚡ Electrical',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Icon(
                                category == 'furniture' ? Icons.chair_rounded : Icons.flash_on_rounded,
                                color: Colors.white.withOpacity(0.85),
                                size: 32,
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.statusCompleted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () => _updateRequestStatus(req['id'].toString(), 'accepted'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusAccepted, foregroundColor: Colors.white),
                    child: const Text('Accept & Schedule Fix'),
                  )
                else if (status == 'accepted')
                  ElevatedButton(
                    onPressed: () => _updateRequestStatus(req['id'].toString(), 'completed'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCompleted, foregroundColor: Colors.white),
                    child: const Text('Mark Issue Resolved ✓'),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
