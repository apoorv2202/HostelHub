// ─────────────────────────────────────────────
//  RegistrationScreen — Complete profile setup
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass.dart';
import '../main_scaffold.dart';
import '../../models/user.dart';
import 'verification_states_screens.dart';
import '../../services/squidex_service.dart';
import '../../models/models.dart';


class RegistrationScreen extends StatefulWidget {
  final String phone;

  const RegistrationScreen({super.key, required this.phone});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  String? _selectedCollege;
  String? _selectedHostel;
  String? _messCardPath;
  String? _idCardPath;
  String _selectedRole = 'student';

  List<CollegeModel> _colleges = [];
  List<HostelModel> _allHostels = [];
  bool _isLoadingData = true;

  CollegeModel? _selectedCollegeModel;

  List<String> get _hostels {
    if (_selectedCollegeModel == null) return [];
    return _allHostels
        .where((h) => h.collegeId == _selectedCollegeModel!.id)
        .map((h) => h.name)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _detectRole();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final squidex = SquidexService();
      final colleges = await squidex.getColleges();
      final hostels = await squidex.getHostels();
      if (mounted) {
        setState(() {
          _colleges = colleges;
          _allHostels = hostels;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _detectRole() {
    final cleanPhone = widget.phone.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
    final match = demoUsers.firstWhere(
      (u) => u.phone == cleanPhone,
      orElse: () => const DemoUser(phone: '', role: 'student', college: '', hostel: '', id: '', room: ''),
    );
    if (match.phone.isNotEmpty) {
      setState(() {
        _selectedRole = match.role;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  // ── Simulate image picker ─────────────────
  Future<void> _pickImage(bool isMessCard) async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      if (isMessCard) {
        _messCardPath = '/mock/mess_card.jpg';
      } else {
        _idCardPath = '/mock/id_card.jpg';
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMessCard ? 'Mess Card selected ✓' : 'ID Card selected ✓'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  bool _isCollegeMatch(String demoCollege, String selectedCollege) {
    final d = demoCollege.toLowerCase().trim();
    final s = selectedCollege.toLowerCase().trim();
    if (d == s) return true;
    if (d.contains(s) || s.contains(d)) return true;
    
    final Map<String, List<String>> abbreviations = {
      'rvce': ['rv', 'rvce', 'rv college', 'r.v.'],
      'bms': ['bms', 'bmsce', 'bms college', 'b.m.s.'],
      'pes': ['pes', 'pesu', 'pes university', 'p.e.s.'],
      'ramaiah': ['ramaiah', 'msrit', 'ms ramaiah', 'm. s. ramaiah'],
    };
    
    for (final entry in abbreviations.entries) {
      final key = entry.key;
      final synonyms = entry.value;
      final isDemoMatching = d.contains(key) || synonyms.any((syn) => d.contains(syn));
      final isSelectedMatching = s.contains(key) || synonyms.any((syn) => s.contains(syn));
      if (isDemoMatching && isSelectedMatching) {
        return true;
      }
    }
    return false;
  }

  String _getCollegeShortName(String fullName) {
    final name = fullName.toLowerCase();
    if (name.contains('rv') || name.contains('r.v.')) return 'RVCE';
    if (name.contains('bms') || name.contains('b.m.s.')) return 'BMS';
    if (name.contains('pes') || name.contains('p.e.s.')) return 'PES';
    if (name.contains('ramaiah') || name.contains('msrit')) return 'Ramaiah';
    return fullName;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) {
      _showError('Please select your college');
      return;
    }
    if (_selectedHostel == null) {
      _showError('Please select your hostel');
      return;
    }

    if (_selectedRole != 'student') {
      final cleanPhone = widget.phone.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
      final match = demoUsers.firstWhere(
        (u) => u.phone == cleanPhone,
        orElse: () => const DemoUser(phone: '', role: '', college: '', hostel: '', id: '', room: ''),
      );

      if (match.phone.isNotEmpty) {
        if (!_isCollegeMatch(match.college, _selectedCollege!)) {
          _showError('Selected college does not match this account.');
          return;
        }
        if (match.id.isNotEmpty && match.id.toLowerCase() != _idCtrl.text.trim().toLowerCase()) {
          _showError('Selected Staff ID does not match this account.');
          return;
        }
      }
    }

    final provider = context.read<AppProvider>();
    bool success = true;
    final shortCollege = _getCollegeShortName(_selectedCollege!);

    if (_selectedRole == 'student') {
      await provider.register(
        name: _nameCtrl.text.trim(),
        phone: widget.phone,
        college: shortCollege,
        hostel: _selectedHostel!,
        roomNumber: _roomCtrl.text.trim(),
        messCardPath: _messCardPath,
        idCardPath: _idCardPath,
      );
    } else {
      UserRole staffRole = UserRole.warden;
      if (_selectedRole == 'cleaner') staffRole = UserRole.cleaning;
      if (_selectedRole == 'canteen') staffRole = UserRole.canteen;
      if (_selectedRole == 'maintenance') staffRole = UserRole.maintenance;

      success = await provider.registerStaff(
        name: _nameCtrl.text.trim(),
        phone: widget.phone,
        college: shortCollege,
        staffId: _idCtrl.text.trim(),
        role: staffRole,
        idCardPath: _idCardPath,
      );
    }

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PendingVerificationScreen(user: provider.user!),
        ),
        (_) => false,
      );
    } else if (mounted) {
      _showError(provider.errorMessage ?? 'Registration failed.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.statusRejected));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Progress indicator ─────────────────────
                    _buildProgressBar(),

                    const SizedBox(height: 28),

                    // ── Step 1 heading ─────────────────────────
                    _buildStepHeader('1', 'Personal Details'),

                    const SizedBox(height: 20),

                    // ── Name ──────────────────────────────────
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textGrey),
                        hintText: 'Rahul Sharma',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter your name' : null,
                    ),

                    const SizedBox(height: 16),

                    // ── Phone (read-only) ─────────────────────
                    TextFormField(
                      initialValue: '+91 ${widget.phone}',
                      readOnly: true,
                      style: const TextStyle(color: AppTheme.textMedium),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textGrey),
                        filled: true,
                        fillColor: AppTheme.surfaceDark,
                      ),
                    ),

                    if (_selectedRole != 'student') ...[
                      TextFormField(
                        controller: _idCtrl,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(
                          labelText: 'Staff ID',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textGrey),
                          hintText: 'e.g., RVCE-WARDEN-01',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your Staff ID';
                          }
                          final cleanId = v.trim().toUpperCase();
                          final cleanPhone = widget.phone.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
                          final match = demoUsers.firstWhere(
                            (u) => u.phone == cleanPhone,
                            orElse: () => const DemoUser(phone: '', role: '', college: '', hostel: '', id: '', room: ''),
                          );
                          if (match.phone.isNotEmpty && match.id.toUpperCase() != cleanId) {
                            return 'Invalid Staff ID for this account.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 28),

                    // ── Step 2 heading ─────────────────────────
                    _buildStepHeader('2', 'Hostel Details'),

                    const SizedBox(height: 20),

                    // ── College dropdown ──────────────────────
                    _isLoadingData
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<CollegeModel>(
                      value: _selectedCollegeModel,
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'College',
                        prefixIcon: Icon(Icons.school_outlined, color: AppTheme.textGrey),
                      ),
                      hint: const Text('Select your college', style: TextStyle(color: AppTheme.textFaint)),
                      isExpanded: true,
                      items: _colleges
                          .map((c) => DropdownMenuItem<CollegeModel>(
                                value: c,
                                child: Text(c.name, style: const TextStyle(color: AppTheme.textWhite)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedCollegeModel = val;
                        _selectedCollege = val?.name;
                        _selectedHostel = null; // reset hostel
                      }),
                      validator: (v) =>
                          v == null ? 'Please select a college' : null,
                    ),

                    const SizedBox(height: 16),

                    // ── Hostel dropdown ───────────────────────
                    _isLoadingData
                    ? const SizedBox.shrink()
                    : DropdownButtonFormField<String>(
                      value: _selectedHostel,
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Hostel',
                        prefixIcon: const Icon(Icons.apartment_outlined, color: AppTheme.textGrey),
                        filled: true,
                        fillColor: _selectedCollegeModel == null
                            ? AppTheme.surfaceDark.withOpacity(0.5)
                            : AppTheme.surfaceDark,
                      ),
                      hint: Text(
                        _selectedCollegeModel == null
                            ? 'Select college first'
                            : 'Select your hostel',
                        style: const TextStyle(color: AppTheme.textFaint),
                      ),
                      isExpanded: true,
                      items: _hostels
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text(h, style: const TextStyle(color: AppTheme.textWhite)),
                              ))
                          .toList(),
                      onChanged: _selectedCollegeModel == null
                          ? null
                          : (val) => setState(() => _selectedHostel = val),
                      validator: (v) =>
                          v == null ? 'Please select a hostel' : null,
                    ),

                    const SizedBox(height: 16),

                    // ── Room number ───────────────────────────
                    TextFormField(
                      controller: _roomCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'Room Number',
                        prefixIcon: Icon(Icons.meeting_room_outlined, color: AppTheme.textGrey),
                        hintText: 'e.g., A-204',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter your room number'
                          : null,
                    ),

                    const SizedBox(height: 28),

                    // ── Step 3 heading ─────────────────────────
                    _buildStepHeader('3', 'Upload Documents'),

                    const SizedBox(height: 8),
                    const Text(
                      'Upload your cards for verification. You can skip and upload later.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Mess Card upload ──────────────────────
                    ImageUploadTile(
                      label: 'Mess Card',
                      selectedPath: _messCardPath,
                      icon: Icons.credit_card_rounded,
                      onTap: () => _pickImage(true),
                    ),

                    const SizedBox(height: 12),

                    // ── ID Card upload ────────────────────────
                    ImageUploadTile(
                      label: 'College ID Card',
                      selectedPath: _idCardPath,
                      icon: Icons.badge_rounded,
                      onTap: () => _pickImage(false),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit button ─────────────────────────
                    GradientButton(
                      label: 'Create Account',
                      onPressed: _register,
                      loading: isLoading,
                      icon: Icons.arrow_forward_rounded,
                    ),

                    const SizedBox(height: 12),

                    // ── Terms ─────────────────────────────────
                    const Center(
                      child: Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step header widget ────────────────────
  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppTheme.primaryOrange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Progress bar ──────────────────────────
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profile Setup',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            Text(
              '${_getProgress()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _getProgress() / 100,
            backgroundColor: AppTheme.primaryLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  int _getProgress() {
    int progress = 0;
    if (_nameCtrl.text.isNotEmpty) progress += 20;
    if (_selectedCollege != null) progress += 20;
    if (_selectedHostel != null) progress += 20;
    if (_roomCtrl.text.isNotEmpty) progress += 20;
    if (_messCardPath != null || _idCardPath != null) progress += 20;
    return progress;
  }
}
