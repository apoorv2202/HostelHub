import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../widgets/glass.dart';
import 'phone_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _logoTapCount = 0; // Tap counter for secret Admin entry

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleLogoTap() {
    _logoTapCount++;
    if (_logoTapCount == 5) {
      _logoTapCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Secret Admin entrance unlocked! Directing to Phone OTP login...'),
          backgroundColor: AppTheme.statusPending,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PhoneLoginScreen(role: UserRole.warden),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: AuroraBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _handleLogoTap,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: AppTheme.orangeGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hostel Hub',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textWhite,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your campus life, simplified',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildRoleCard(
                          context,
                          role: UserRole.student,
                          title: 'Student',
                          subtitle: 'Access room requests, order canteen food, and report repairs',
                          icon: '🎓',
                          gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        const SizedBox(height: 12),
                        _buildRoleCard(
                          context,
                          role: UserRole.warden,
                          title: 'Warden',
                          subtitle: 'Verify student documents, manage requests, and approvals',
                          icon: '🛡️',
                          gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        const SizedBox(height: 12),
                        _buildRoleCard(
                          context,
                          role: UserRole.cleaning,
                          title: 'Cleaner',
                          subtitle: 'View, accept, and mark room cleaning tickets as done',
                          icon: '🧹',
                          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        const SizedBox(height: 12),
                        _buildRoleCard(
                          context,
                          role: UserRole.canteen,
                          title: 'Canteen',
                          subtitle: 'Manage late-night food items, quantities, and orders',
                          icon: '🍽️',
                          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        const SizedBox(height: 12),
                        _buildRoleCard(
                          context,
                          role: UserRole.maintenance,
                          title: 'Maintenance',
                          subtitle: 'Report electrical issues, accept tasks, and upload photos',
                          icon: '🔧',
                          gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRole role,
    required String title,
    required String subtitle,
    required String icon,
    required List<Color> gradient,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusSm,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneLoginScreen(role: role),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textFaint,
          ),
        ],
      ),
    );
  }
}
