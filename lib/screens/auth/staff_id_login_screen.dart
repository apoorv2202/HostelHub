import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class StaffIdLoginScreen extends StatefulWidget {
  final UserRole role;

  const StaffIdLoginScreen({super.key, required this.role});

  @override
  State<StaffIdLoginScreen> createState() => _StaffIdLoginScreenState();
}

class _StaffIdLoginScreenState extends State<StaffIdLoginScreen> {
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = context.read<AppProvider>();
    final success = await provider.loginWithIdCard(
      _idController.text.trim(),
      widget.role,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in successfully as ${widget.role.label}! ✓'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Verification failed.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('${widget.role.label} Verification'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.role.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify as ${widget.role.label}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your ${widget.role.label} ID Card / Staff ID number below to proceed.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _idController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'ID Card / Staff ID Number',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primary),
                    hintText: 'e.g. WDN001, CLN001, CAN001, MNT001',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your ID number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Verify ID & Login',
                  onTap: _login,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo mode: Enter any ID number (e.g. WDN001 for Warden, CAN001 for Canteen, CLN001 for Cleaner, MNT001 for Maintenance) to instantly verify and enter.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            height: 1.5,
                          ),
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
}
