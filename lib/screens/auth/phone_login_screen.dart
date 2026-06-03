// lib/screens/auth/phone_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass.dart';
import '../../widgets/common_widgets.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  final UserRole role;

  const PhoneLoginScreen({super.key, required this.role});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final success = await provider.sendOtp(_phoneController.text.trim());
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: _phoneController.text.trim(),
            role: widget.role,
          ),
        ),
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppTheme.statusRejected,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: AuroraBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),

                      // ── Logo + Brand ───────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppTheme.orangeGradient,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryOrange.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Hostel Hub',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textWhite,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Signing in as ${widget.role.label} ⚡',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 42),

                      // ── Heading ────────────────────────────────
                      const Text(
                        'Welcome! 👋',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your mobile number to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Phone input ────────────────────────────
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: AppTheme.textWhite,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          counterText: '',
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(),
                          hintText: '9876543210',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (val.length != 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          final cleanPhone = val.replaceAll(RegExp(r'\D'), '');
                          final matchingUsers = demoUsers.where((u) => u.phone == cleanPhone).toList();
                          if (matchingUsers.isEmpty) {
                            return 'Phone number not registered in the system.';
                          }
                          final hasMatchingRole = matchingUsers.any((u) {
                            if (widget.role == UserRole.student && u.role == 'student') return true;
                            if (widget.role == UserRole.warden && u.role == 'warden') return true;
                            if (widget.role == UserRole.cleaning && u.role == 'cleaner') return true;
                            if (widget.role == UserRole.canteen && u.role == 'canteen') return true;
                            if (widget.role == UserRole.maintenance && u.role == 'maintenance') return true;
                            return false;
                          });
                          if (!hasMatchingRole) {
                            return 'This number is registered under a different role.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // ── CTA ────────────────────────────────────
                      GradientButton(
                        label: 'Send OTP',
                        onPressed: _sendOtp,
                        loading: isLoading,
                        icon: Icons.send_rounded,
                      ),

                      const SizedBox(height: 20),

                      // ── Demo note ──────────────────────────────
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        radius: AppTheme.radiusSm,
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDemoNoteForRole(widget.role),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textWhite,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Feature highlights ─────────────────────
                      _buildFeatureRow(
                          Icons.cleaning_services_rounded,
                          'Room Services',
                          'Request cleaning anytime'),
                      _buildFeatureRow(
                          Icons.restaurant_menu_rounded,
                          'Night Canteen',
                          'Order food late night'),
                      _buildFeatureRow(Icons.build_rounded, 'Maintenance',
                          'Report issues instantly'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textWhite,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDemoNoteForRole(UserRole role) {
    String numberList = '';
    switch (role) {
      case UserRole.student:
        numberList = '• RVCE: 9876500004 or 9876500005\n'
            '• BMS: 9876510004 or 9876510005\n'
            '• PES: 9876520004 or 9876520005\n'
            '• Ramaiah: 9876530004 or 9876530005\n'
            '• Test Number: 9876543210';
        break;
      case UserRole.warden:
        numberList = '• RVCE: 9876500001\n'
            '• BMS: 9876510001\n'
            '• PES: 9876520001\n'
            '• Ramaiah: 9876530001\n'
            '• Test Number: 9876543211';
        break;
      case UserRole.canteen:
        numberList = '• RVCE: 9876500007\n'
            '• BMS: 9876510007\n'
            '• PES: 9876520007\n'
            '• Ramaiah: 9876530007\n'
            '• Test Number: 9876543212';
        break;
      case UserRole.cleaning:
        numberList = '• RVCE: 9876500002\n'
            '• BMS: 9876510002\n'
            '• PES: 9876520002\n'
            '• Ramaiah: 9876530002\n'
            '• Test Number: 9876543213';
        break;
      case UserRole.maintenance:
        numberList = '• RVCE: 9876500003\n'
            '• BMS: 9876510003\n'
            '• PES: 9876520003\n'
            '• Ramaiah: 9876530003\n'
            '• Test Number: 9876543214';
        break;
    }
    return 'Standard Campus Demo Logins (OTP: 123456):\n$numberList';
  }
}
