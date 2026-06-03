import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../main_scaffold.dart';
import '../admin_dashboard.dart';
import 'verification_states_screens.dart';

class StaffRegistrationScreen extends StatefulWidget {
  final String phone;
  final UserRole role;

  const StaffRegistrationScreen({
    super.key,
    required this.phone,
    required this.role,
  });

  @override
  State<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends State<StaffRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  String? _selectedCollege;
  String? _idCardPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _idCardPath = '/mock/staff_id_card.jpg';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional ID Card selected ✓'),
          backgroundColor: AppTheme.statusCompleted,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) {
      _showError('Please select your college');
      return;
    }
    if (_idCardPath == null) {
      _showError('Please upload your professional ID Card for verification');
      return;
    }

    final cleanPhone = widget.phone.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
    final match = demoUsers.firstWhere(
      (u) => u.phone == cleanPhone,
      orElse: () => const DemoUser(phone: '', role: '', college: '', hostel: '', id: '', room: ''),
    );

    if (match.phone.isNotEmpty) {
      if (!match.college.toLowerCase().contains(_selectedCollege!.toLowerCase()) &&
          !_selectedCollege!.toLowerCase().contains(match.college.toLowerCase())) {
        _showError('Selected college does not match this account.');
        return;
      }
      if (match.id.toLowerCase() != _idCtrl.text.trim().toLowerCase()) {
        _showError('Staff ID does not match this account.');
        return;
      }
    }

    final provider = context.read<AppProvider>();
    final success = await provider.registerStaff(
      name: _nameCtrl.text.trim(),
      phone: widget.phone,
      college: _selectedCollege!,
      staffId: _idCtrl.text.trim(),
      role: widget.role,
      idCardPath: _idCardPath,
    );

    if (success && mounted) {
      final user = provider.user!;
      if (widget.role == UserRole.warden) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(user: user),
          ),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PendingVerificationScreen(user: user),
          ),
          (_) => false,
        );
      }
    } else if (mounted) {
      _showError(provider.errorMessage ?? 'Registration failed.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.statusRejected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Staff Registration'),
        backgroundColor: Colors.transparent,
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete Staff Profile 🛡️',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete your profile details as ${widget.role.label} below.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 32),

                  // ── Full Name ─────────────────────────────
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textGrey),
                      hintText: 'e.g. Ramesh Kumar',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Phone Number (read-only) ──────────────
                  TextFormField(
                    initialValue: '+91 ${widget.phone}',
                    readOnly: true,
                    style: const TextStyle(color: AppTheme.textGrey),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textGrey),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Staff ID Number ───────────────────────
                  TextFormField(
                    controller: _idCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      labelText: 'Staff ID Number / Employee ID',
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textGrey),
                      hintText: widget.role == UserRole.warden ? 'e.g., RVCE-WARDEN-01' : 'e.g., BMS-CLEANER-01',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your Staff ID';
                      }
                      final cleanId = v.trim().toUpperCase();
                      if (_selectedCollege != null) {
                        final campus = _selectedCollege!.toUpperCase();
                        String roleCode = '';
                        switch (widget.role) {
                          case UserRole.warden:
                            roleCode = 'WARDEN';
                            break;
                          case UserRole.cleaning:
                            roleCode = 'CLEANER';
                            break;
                          case UserRole.maintenance:
                            roleCode = 'MAINT';
                            break;
                          case UserRole.canteen:
                            roleCode = 'CANTEEN';
                            break;
                          default:
                            roleCode = 'STAFF';
                        }
                        final expectedId = '$campus-$roleCode-01';
                        if (cleanId != expectedId) {
                          return 'Invalid Staff ID. For $_selectedCollege, use default: $expectedId';
                        }
                      }
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

                  // ── College dropdown ──────────────────────
                  DropdownButtonFormField<String>(
                    value: _selectedCollege,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      labelText: 'Select Campus/College',
                      prefixIcon: Icon(Icons.school_outlined, color: AppTheme.textGrey),
                    ),
                    hint: const Text('Select your college', style: TextStyle(color: AppTheme.textFaint)),
                    isExpanded: true,
                    items: collegeHostels.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: const TextStyle(color: AppTheme.textWhite)),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCollege = val),
                    validator: (v) => v == null ? 'Please select a college' : null,
                  ),
                  const SizedBox(height: 28),

                  // ── Image Upload Title ───────────────────
                  const Text(
                    'Upload ID Card',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textWhite),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please upload your professional college ID Card for approval.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 16),

                  // ── ID Card picker container ──────────────
                  GestureDetector(
                    onTap: _pickImage,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      radius: AppTheme.radiusSm,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _idCardPath != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                            color: _idCardPath != null ? AppTheme.statusCompleted : AppTheme.primaryOrange,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _idCardPath != null ? 'ID Card Uploaded ✓' : 'Upload College ID Card',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _idCardPath != null ? AppTheme.statusCompleted : AppTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Submit Button ────────────────────────
                  GradientButton(
                    label: 'Register Profile & Apply',
                    onPressed: _register,
                    loading: isLoading,
                    icon: Icons.assignment_turned_in_rounded,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
