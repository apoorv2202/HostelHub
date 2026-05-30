import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'auth/role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _lostRequests = [];
  List<Map<String, dynamic>> _pendingProfiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchWardenData();
  }

  Future<void> _fetchWardenData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch RVCE students (scoped by college as requested!)
      final studentRes = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'student')
          .eq('college', widget.user.college);

      // 2. Fetch lost requests
      final lostRes = await _supabase
          .from('lost_requests')
          .select('*, profiles(name, room_number, hostel, college)')
          .order('created_at', ascending: false);

      // Filter lost requests by Warden's college canteen/hostel
      final List<Map<String, dynamic>> scopedLost = [];
      for (var r in lostRes as List) {
        final profile = r['profiles'];
        if (profile != null && profile['college'] == widget.user.college) {
          scopedLost.add(r as Map<String, dynamic>);
        }
      }

      // 3. Fetch pending registrations for Warden's college
      final pendingRes = await _supabase
          .from('profiles')
          .select()
          .eq('verification_status', 'pending')
          .eq('college', widget.user.college);

      setState(() {
        _students = List<Map<String, dynamic>>.from(studentRes as List);
        _lostRequests = scopedLost;
        _pendingProfiles = List<Map<String, dynamic>>.from(pendingRes as List);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching Warden data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProfile(String profileId, bool approve) async {
    try {
      final status = approve ? 'verified' : 'rejected';
      await _supabase
          .from('profiles')
          .update({'verification_status': status})
          .eq('id', profileId);

      _showSnack(
        'Profile ${approve ? "approved & verified" : "rejected"} successfully!',
        approve ? AppTheme.statusCompleted : AppTheme.statusPending,
      );
      _fetchWardenData();
    } catch (e) {
      _showSnack('Error updating profile: $e', Colors.red);
    }
  }

  Future<void> _approveLostRequest(String reqId, String newStatus) async {
    try {
      await _supabase
          .from('lost_requests')
          .update({'status': newStatus})
          .eq('id', reqId);

      _showSnack('Lost request status updated to $newStatus ✓', AppTheme.statusCompleted);
      _fetchWardenData();
    } catch (e) {
      _showSnack('Error updating lost request: $e', Colors.red);
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
            const Text('Warden Dashboard'),
            Text(
              '${widget.user.college} Campus • Warden ${widget.user.name.split(' ').first}',
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
            onPressed: _fetchWardenData,
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
            Tab(text: 'Students'),
            Tab(text: 'Lost Cards'),
            Tab(text: 'Approvals'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStudentTab(),
                _buildLostTab(),
                _buildApprovalsTab(),
                _buildInfoTab(),
              ],
            ),
    );
  }

  Widget _buildStudentTab() {
    if (_students.isEmpty) {
      return const Center(child: Text('No students registered on this campus.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final stu = _students[index];
        final isVerified = stu['verification_status'] == 'verified';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isVerified
                  ? AppTheme.statusCompleted.withOpacity(0.1)
                  : AppTheme.statusPending.withOpacity(0.1),
              child: Text(
                isVerified ? '✓' : '?',
                style: TextStyle(
                  color: isVerified ? AppTheme.statusCompleted : AppTheme.statusPending,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              stu['name'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Room ${stu['room_number'] ?? 'N/A'} · ${stu['hostel'] ?? 'N/A'}\nPhone: ${stu['phone'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppTheme.statusCompleted.withOpacity(0.12)
                    : AppTheme.statusPending.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isVerified ? AppTheme.statusCompleted : AppTheme.statusPending,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLostTab() {
    if (_lostRequests.isEmpty) {
      return const Center(child: Text('No lost card requests found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lostRequests.length,
      itemBuilder: (context, index) {
        final req = _lostRequests[index];
        final profile = req['profiles'] ?? {};
        final isApproved = req['status'] == 'approved' || req['status'] == 'completed';

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
                      req['item_type'] == 'mess_card' ? 'Lost Mess Card 💳' : 'Lost College ID 📛',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? AppTheme.statusCompleted.withOpacity(0.12)
                            : AppTheme.statusPending.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req['status'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? AppTheme.statusCompleted : AppTheme.statusPending,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Student: ${profile['name'] ?? "Unknown Student"}'),
                Text('Room: ${profile['room_number'] ?? "N/A"} · Hostel: ${profile['hostel'] ?? "N/A"}'),
                Text('Payment: ${req['payment_status'] ?? "pending"}'),
                const SizedBox(height: 12),
                if (req['status'] == 'pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _approveLostRequest(req['id'].toString(), 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusCompleted,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _approveLostRequest(req['id'].toString(), 'rejected'),
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
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

  Widget _buildApprovalsTab() {
    if (_pendingProfiles.isEmpty) {
      return const Center(child: Text('No pending profile approvals. ✓'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingProfiles.length,
      itemBuilder: (context, index) {
        final profile = _pendingProfiles[index];
        final roleStr = profile['role'] ?? 'student';
        final isStudent = roleStr == 'student';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profile['name'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textWhite),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(roleStr).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleStr.toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _getRoleColor(roleStr),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Phone: ${profile['phone'] ?? "N/A"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                Text('Hostel: ${profile['hostel'] ?? "N/A"} · Room: ${profile['room_number'] ?? "N/A"}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                const SizedBox(height: 16),
                
                // Document approval row
                const Text(
                  'ATTACHED DOCUMENTS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMedium, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDocTile(
                        label: isStudent ? 'College ID' : 'Staff Professional ID',
                        icon: Icons.badge_rounded,
                        onTap: () => _showDocumentDialog(context, profile, 'id_card'),
                      ),
                    ),
                    if (isStudent) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDocTile(
                          label: 'Mess Card',
                          icon: Icons.credit_card_rounded,
                          onTap: () => _showDocumentDialog(context, profile, 'mess_card'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveProfile(profile['id'].toString(), true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusCompleted,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Approve & Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _approveProfile(profile['id'].toString(), false),
                      child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return Colors.blue;
      case 'canteen':
        return Colors.orange;
      case 'cleaner':
        return Colors.green;
      case 'maintenance':
        return Colors.purple;
      default:
        return AppTheme.textGrey;
    }
  }

  Widget _buildDocTile({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                  const Text('Click to view ✓', style: TextStyle(color: AppTheme.statusCompleted, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, Map<String, dynamic> profile, String docType) {
    final name = profile['name'] ?? 'Unknown User';
    final role = profile['role'] ?? 'student';
    final college = profile['college'] ?? 'RV College of Engineering';
    final hostel = profile['hostel'] ?? 'N/A';
    final room = profile['room_number'] ?? 'N/A';
    final phone = profile['phone'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          height: docType == 'id_card' ? 440 : 260,
          decoration: BoxDecoration(
            gradient: docType == 'id_card'
                ? const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFF7C2D12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        college,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              if (docType == 'id_card') ...[
                const SizedBox(height: 20),
                // Avatar placeholder
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    role == 'student' ? Icons.person_rounded : Icons.shield_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  role.toString().toUpperCase(),
                  style: TextStyle(
                    color: docType == 'id_card' ? const Color(0xFF60A5FA) : const Color(0xFFFDBA74),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _cardRow('HOSTEL', hostel),
                        _cardRow('ROOM / ID', room),
                        _cardRow('CONTACT', phone),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Barcode simulation
                Container(
                  width: double.infinity,
                  height: 36,
                  color: Colors.white.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      24,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: (i % 3 == 0) ? 3 : ((i % 4 == 0) ? 1 : 2),
                        height: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Mess Card
                const SizedBox(height: 20),
                const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 42),
                const SizedBox(height: 8),
                const Text(
                  'HOSTEL HUB MESS PASS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _cardRow('HOLDER', name),
                      _cardRow('CAMPUS', college),
                      _cardRow('HOSTEL', '$hostel ($room)'),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'ACTIVE MESS SUBSCRIPTION ✓',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warden Control Panel',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage and monitor campus rooms, student card status, and registration requests.',
            style: TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Warden Name', widget.user.name),
          _buildInfoRow('Campus College', widget.user.college),
          _buildInfoRow('Access Role', widget.user.role.label),
          _buildInfoRow('RVCE Scoping', 'Active (Scoped canteens & requests)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
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
