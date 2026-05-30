import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass.dart';
import '../../models/user.dart';
import '../../models/user_model.dart';
import 'role_selection_screen.dart';

class PendingVerificationScreen extends StatelessWidget {
  final UserModel user;

  const PendingVerificationScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.statusPending.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.statusPending.withOpacity(0.35)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.hourglass_empty_rounded,
                            color: AppTheme.statusPending,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Account Pending Approval',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hello, ${user.name}! Your profile as a ${user.role.label} is currently pending review by your campus Warden (or Admin for Wardens).',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppTheme.primaryOrange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'College Campus: ${user.college}',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await context.read<AppProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.textGrey),
                  label: const Text(
                    'Logout & Change Role',
                    style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RejectedVerificationScreen extends StatelessWidget {
  final UserModel user;

  const RejectedVerificationScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.statusRejected.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.statusRejected.withOpacity(0.35)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.gpp_bad_rounded,
                            color: AppTheme.statusRejected,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Verification Rejected',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textWhite,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We are sorry, ${user.name}. Your profile registration as a ${user.role.label} was rejected by the campus authorities.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Please verify your uploaded documents and details, then try registering again.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.statusPending,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GradientButton(
                  label: 'Re-Register Profile',
                  icon: Icons.refresh_rounded,
                  onPressed: () async {
                    // Logs out and deletes their current profiles row to let them re-register!
                    final provider = context.read<AppProvider>();
                    final supabase = Supabase.instance.client;
                    try {
                      final userId = supabase.auth.currentUser?.id;
                      if (userId != null) {
                        await supabase.from('profiles').delete().eq('id', userId);
                      }
                    } catch (e) {
                      print('Error deleting rejected profile: $e');
                    }
                    await provider.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
