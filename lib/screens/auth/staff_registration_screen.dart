import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../models/models.dart';
import '../../services/squidex_service.dart';
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

  List<CollegeModel> _colleges = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    try {
      final squidex = SquidexService();
      final colleges = await squidex.getColleges();
      if (mounted) {
        setState(() {
          _colleges = colleges;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
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
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                            hintText: widget.role == UserRole.warden ? 'e.g. WDN001' : 'e.g. CLN001',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter your Staff ID' : null,
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
                          items: _colleges
                              .map((c) => DropdownMenuItem(
                                    value: c.name,
                                    child: Text(c.name, style: const TextStyle(color: AppTheme.textWhite)),
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
