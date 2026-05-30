import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'auth/role_selection_screen.dart';

class CleaningDashboardScreen extends StatefulWidget {
  final UserModel user;

  const CleaningDashboardScreen({super.key, required this.user});

  @override
  State<CleaningDashboardScreen> createState() =>
      _CleaningDashboardScreenState();
}

class _CleaningDashboardScreenState extends State<CleaningDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _filter = 'All';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchCleaningRequests();
  }

  Future<void> _fetchCleaningRequests() async {
    setState(() => _isLoading = true);
    try {
      // Fetch cleaning requests joined with student profiles
      // Use FK hint to disambiguate (service_requests has two FKs to profiles)
      final response = await _supabase
          .from('service_requests')
          .select('*, profiles!service_requests_user_id_fkey(name, room_number, hostel, college)')
          .order('created_at', ascending: false);

      // Filter requests by Cleaner's college
      // (PostgREST may return embed key as 'profiles' or the FK-hint name)
      final List<Map<String, dynamic>> scopedRequests = [];
      for (var r in response as List) {
        final profile = (r['profiles!service_requests_user_id_fkey'] ?? r['profiles']) as Map?;
        if (profile != null && profile['college'] == widget.user.college) {
          scopedRequests.add(r as Map<String, dynamic>);
        }
      }

      setState(() {
        _requests = scopedRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cleaning requests: $e');
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

  Future<void> _acceptRequest(String reqId) async {
    try {
      final userResponse = _supabase.auth.currentUser;
      final assignedId = userResponse?.id;
      
      await _supabase
          .from('service_requests')
          .update({
            'status': 'accepted',
            'assigned_cleaner': assignedId,
          })
          .eq('id', reqId);

      _showSnack('Request accepted! Assigned to you.', AppTheme.statusAccepted);
      _fetchCleaningRequests();
    } catch (e) {
      _showSnack('Error accepting request: $e', Colors.red);
    }
  }

  Future<void> _completeRequest(String reqId) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'status': 'completed'})
          .eq('id', reqId);

      _showSnack('Cleaning request marked as completed! ✓', AppTheme.statusCompleted);
      _fetchCleaningRequests();
    } catch (e) {
      _showSnack('Error completing request: $e', Colors.red);
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
            const Text('Cleaning Dashboard'),
            Text(
              '${widget.user.college} Campus • Cleaning Staff ${widget.user.name.split(' ').first}',
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
            onPressed: _fetchCleaningRequests,
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
                          'No cleaning requests in this category.',
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
          _statBox('$pending', 'Pending', AppTheme.statusPending),
          _statBox('$active', 'Active', AppTheme.statusAccepted),
          _statBox('$completed', 'Completed', AppTheme.statusCompleted),
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
        final profile = req['profiles!service_requests_user_id_fkey'] ?? req['profiles'] ?? {};
        final status = req['status'];

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
                      req['cleaning_type'] == 'deep_cleaning' ? 'Deep Cleaning 🧹' : 'Normal Cleaning 🧹',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      status.toString().toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'completed'
                            ? AppTheme.statusCompleted
                            : (status == 'accepted' ? AppTheme.statusAccepted : AppTheme.statusPending),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Student: ${profile['name'] ?? "Unknown Student"}'),
                Text('Room: ${profile['room_number'] ?? "N/A"} · Hostel: ${profile['hostel'] ?? "N/A"}'),
                if (req['description'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req['description'],
                      style: const TextStyle(fontSize: 13, color: AppTheme.textWhite),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () => _acceptRequest(req['id'].toString()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusAccepted, foregroundColor: Colors.white),
                    child: const Text('Accept Cleaning Request'),
                  )
                else if (status == 'accepted')
                  ElevatedButton(
                    onPressed: () => _completeRequest(req['id'].toString()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusCompleted, foregroundColor: Colors.white),
                    child: const Text('Mark as Done'),
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
