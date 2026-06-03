// lib/screens/auth/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass.dart';
import '../../models/user.dart';
import '../../models/user_model.dart';
import 'registration_screen.dart';
import 'staff_registration_screen.dart';
import 'verification_states_screens.dart';
import '../main_scaffold.dart';
import '../admin_dashboard.dart';
import '../canteen_dashboard.dart';
import '../cleaning_dashboard.dart';
import '../maintenance_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final UserRole role;

  const OtpScreen({super.key, required this.phone, required this.role});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  void _goToRegistration() {
    if (widget.role == UserRole.student) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(phone: widget.phone),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StaffRegistrationScreen(phone: widget.phone, role: widget.role),
        ),
      );
    }
  }

  void _goToDashboard(UserModel user) {
    final status = user.verificationStatus;
    if (status == VerificationStatus.pending) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PendingVerificationScreen(user: user),
        ),
        (_) => false,
      );
    } else if (status == VerificationStatus.rejected) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RejectedVerificationScreen(user: user),
        ),
        (_) => false,
      );
    } else {
      Widget dashboard;
      switch (user.role) {
        case UserRole.student:
          dashboard = const MainScaffold();
          break;
        case UserRole.warden:
          dashboard = AdminDashboardScreen(user: user);
          break;
        case UserRole.canteen:
          dashboard = CanteenDashboardScreen(user: user);
          break;
        case UserRole.cleaning:
          dashboard = CleaningDashboardScreen(user: user);
          break;
        case UserRole.maintenance:
          dashboard = MaintenanceDashboardScreen(user: user);
          break;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
        (_) => false,
      );
    }
  }

  void _showMockChoiceDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.account_circle_rounded, color: AppTheme.primaryOrange, size: 28),
            SizedBox(width: 10),
            Text(
              'Mock Profile Detected',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An existing profile was found for this mock number:',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user.name}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Role: ${widget.role.label}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      Text(
                        user.verificationStatus.name.toUpperCase(),
                        style: TextStyle(
                          color: user.verificationStatus == VerificationStatus.verified
                              ? AppTheme.statusCompleted
                              : AppTheme.statusPending,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select "Login directly" to use this verified profile, or "Test Signup Flow" to simulate a new registration.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _goToRegistration(); // Go to registration screen
                  },
                  child: const Text('Test Signup Flow', style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _goToDashboard(user); // Log in directly
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Login Directly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() => _error = null);
    final provider = context.read<AppProvider>();
    final success = await provider.verifyOtp(_otp);
    if (success && mounted) {
      final user = provider.user;
      final cleanPhone = widget.phone.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
      final isMock = demoUsers.any((u) => u.phone == cleanPhone);

      if (user != null) {
        if (user.role == widget.role) {
          if (isMock) {
            // Profile exists for mock number, let them choose: login directly or test signup
            _showMockChoiceDialog(context, user);
          } else {
            // Real user, always log in directly
            _goToDashboard(user);
          }
        } else {
          setState(() {
            _error = 'This number is registered under a different role. Please select the correct role.';
          });
          provider.logout();
        }
      } else {
        // User has no profile, direct to registration
        _goToRegistration();
      }
    } else if (mounted) {
      setState(() => _error = provider.errorMessage ?? 'Invalid OTP.');
    }
  }

  void _resend() {
    if (_resendCountdown > 0) return;
    setState(() => _resendCountdown = 30);
    _startResendTimer();
    for (var c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Verify Number'),
        backgroundColor: Colors.transparent,
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Icon ──────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    color: AppTheme.primaryOrange,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Enter verification\ncode',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textWhite,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                    children: [
                      const TextSpan(text: 'Sent to +91 '),
                      TextSpan(
                        text: widget.phone,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── OTP Boxes ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _buildOtpBox(i)),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.statusRejected,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // ── Verify button ─────────────────────────
                GradientButton(
                  label: 'Verify & Continue',
                  onPressed: _verify,
                  loading: isLoading,
                ),

                const SizedBox(height: 20),

                // ── Resend ────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _resend,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: [
                          const TextSpan(
                            text: "Didn't receive the code? ",
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                          if (_resendCountdown > 0)
                            TextSpan(
                              text: 'Resend in ${_resendCountdown}s',
                              style: const TextStyle(
                                  color: AppTheme.textFaint),
                            )
                          else
                            const TextSpan(
                              text: 'Resend OTP',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Demo hint ─────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  radius: AppTheme.radiusSm,
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: AppTheme.statusPending, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Demo ${widget.role.label} OTP: 123456',
                        style: const TextStyle(
                          color: AppTheme.statusPending,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppTheme.textWhite,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppTheme.surfaceDark,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryOrange, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
