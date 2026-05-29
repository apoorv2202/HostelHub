// ─────────────────────────────────────────────
//  ProfileScreen — User profile details
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Profile hero header ───────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHero(context, user),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _confirmLogout(context),
                tooltip: 'Logout',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Verification status ────────────────────
                _buildVerificationCard(user),

                const SizedBox(height: 20),

                // ── Personal info ──────────────────────────
                _buildInfoSection(
                  title: 'Personal Information',
                  icon: Icons.person_rounded,
                  children: [
                    InfoRow(
                      icon: Icons.badge_rounded,
                      label: 'Full Name',
                      value: user.name,
                    ),
                    const Divider(height: 0),
                    InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Phone Number',
                      value: '+91 ${user.phone}',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Hostel info ────────────────────────────
                _buildInfoSection(
                  title: 'Hostel Details',
                  icon: Icons.apartment_rounded,
                  children: [
                    InfoRow(
                      icon: Icons.school_rounded,
                      label: 'College',
                      value: user.college,
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                    const Divider(height: 0),
                    InfoRow(
                      icon: Icons.apartment_rounded,
                      label: 'Hostel',
                      value: user.hostel,
                      iconColor: const Color(0xFF10B981),
                    ),
                    const Divider(height: 0),
                    InfoRow(
                      icon: Icons.meeting_room_rounded,
                      label: 'Room Number',
                      value: user.roomNumber,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Documents ──────────────────────────────
                _buildDocumentsSection(user),

                const SizedBox(height: 16),

                // ── Account settings ───────────────────────
                _buildInfoSection(
                  title: 'Account',
                  icon: Icons.settings_rounded,
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (_) {},
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    const Divider(height: 0),
                    _SettingsTile(
                      icon: Icons.help_rounded,
                      label: 'Help & Support',
                      onTap: () => _showHelp(context),
                    ),
                    const Divider(height: 0),
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      label: 'About Hostel Hub',
                      onTap: () {},
                    ),
                    const Divider(height: 0),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      iconColor: AppTheme.error,
                      labelColor: AppTheme.error,
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Version ────────────────────────────────
                const Center(
                  child: Text(
                    'Hostel Hub v1.0.0  ·  Made with ❤️ for students',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textLight),
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile hero ──────────────────────────
  Widget _buildProfileHero(BuildContext context, UserModel user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B5FEF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${user.hostel}, Room ${user.roomNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '+91 ${user.phone}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Verification banner ───────────────────
  Widget _buildVerificationCard(UserModel user) {
    final status = user.verificationStatus;
    final config = _verificationConfig(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config['bgColor'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (config['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config['icon'] as IconData,
              color: config['color'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: config['color'] as Color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: (config['color'] as Color).withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.name.toUpperCase(),
              style: TextStyle(
                color: config['color'] as Color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _verificationConfig(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return {
          'color': AppTheme.warning,
          'bgColor': AppTheme.warningLight,
          'icon': Icons.hourglass_top_rounded,
          'title': 'Verification Pending',
          'subtitle':
              'Your documents are under review. This usually takes 24–48 hours.',
        };
      case VerificationStatus.verified:
        return {
          'color': AppTheme.success,
          'bgColor': AppTheme.successLight,
          'icon': Icons.verified_rounded,
          'title': 'Account Verified ✓',
          'subtitle': 'Your identity has been verified successfully.',
        };
      case VerificationStatus.rejected:
        return {
          'color': AppTheme.error,
          'bgColor': AppTheme.errorLight,
          'icon': Icons.cancel_rounded,
          'title': 'Verification Rejected',
          'subtitle':
              'Your documents were rejected. Please re-upload and try again.',
        };
    }
  }

  // ── Info section wrapper ──────────────────
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ── Documents section ─────────────────────
  Widget _buildDocumentsSection(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.folder_rounded,
                    size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Documents',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _DocumentCard(
                    emoji: '💳',
                    title: 'Mess Card',
                    isUploaded: user.messCardPath != null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DocumentCard(
                    emoji: '🪪',
                    title: 'ID Card',
                    isUploaded: user.idCardPath != null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?'),
        content: const Text(
            'Are you sure you want to logout from Hostel Hub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AppProvider>().logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help & Support',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 20),
            _HelpItem('📞', 'Call Warden Office', '+91 98765 43210'),
            _HelpItem('📧', 'Email Support', 'support@hostelhub.in'),
            _HelpItem('💬', 'WhatsApp', 'Chat with us'),
            _HelpItem('📍', 'Office Hours', 'Mon–Sat, 9 AM – 6 PM'),
          ],
        ),
      ),
    );
  }
}

// ── Document Card ─────────────────────────
class _DocumentCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isUploaded;

  const _DocumentCard({
    required this.emoji,
    required this.title,
    required this.isUploaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUploaded ? AppTheme.successLight : AppTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? AppTheme.success.withOpacity(0.4)
              : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUploaded
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 12,
                color: isUploaded ? AppTheme.success : AppTheme.textLight,
              ),
              const SizedBox(width: 3),
              Text(
                isUploaded ? 'Uploaded' : 'Not Uploaded',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isUploaded ? AppTheme.success : AppTheme.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings tile ─────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: iconColor ?? AppTheme.textMedium),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppTheme.textDark,
                ),
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textLight, size: 18)
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

// ── Help item ─────────────────────────────
class _HelpItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const _HelpItem(this.emoji, this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMedium)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}
