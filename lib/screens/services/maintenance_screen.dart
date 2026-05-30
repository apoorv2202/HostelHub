// ─────────────────────────────────────────────
//  MaintenanceScreen — Report issues
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String? _selectedCategory;
  String? _selectedIssue;
  final _descriptionCtrl = TextEditingController();
  String? _imagePath;
  bool _submitted = false;
  bool _isLoading = false;

  final Map<String, List<_IssueItem>> _issueMap = {
    'Electrician': [
      _IssueItem('💡', 'Light/Tubelight'),
      _IssueItem('🔌', 'Power Socket'),
      _IssueItem('🌀', 'Ceiling Fan'),
      _IssueItem('⚡', 'MCB/Switch Board'),
      _IssueItem('🔋', 'Inverter/Battery'),
      _IssueItem('❓', 'Other Electrical'),
    ],
    'Furniture': [
      _IssueItem('🪑', 'Chair/Table'),
      _IssueItem('🛏️', 'Bed/Cot'),
      _IssueItem('🚪', 'Door/Cupboard'),
      _IssueItem('🪟', 'Window/Lock'),
      _IssueItem('🪞', 'Mirror/Shelf'),
      _IssueItem('❓', 'Other Furniture'),
    ],
  };

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _showSnack('Please select a category');
      return;
    }
    if (_selectedIssue == null) {
      _showSnack('Please select the issue type');
      return;
    }
    if (_descriptionCtrl.text.trim().isEmpty) {
      _showSnack('Please describe the issue');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      context.read<AppProvider>().addMaintenanceRequest(
            category: _selectedCategory!,
            description: _descriptionCtrl.text.trim(),
            imagePath: _imagePath,
          );
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Maintenance 🔧'),
        backgroundColor: AppTheme.bg,
      ),
      body: _submitted
          ? _buildSuccessView()
          : LoadingOverlay(
              isLoading: _isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Text('🔧', style: TextStyle(fontSize: 40)),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report an Issue',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'Our team will fix it ASAP.\nTypically resolved within 24 hours.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMedium,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Category selection ────────────────────
                    const SectionHeader(
                      title: 'Select Category',
                      subtitle: 'What type of issue?',
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        _CategoryCard(
                          emoji: '⚡',
                          title: 'Electrician',
                          subtitle: 'Lights, Fan, Socket',
                          isSelected: _selectedCategory == 'Electrician',
                          color: const Color(0xFFF59E0B),
                          bgColor: AppTheme.surfaceDark,
                          onTap: () => setState(() {
                            _selectedCategory = 'Electrician';
                            _selectedIssue = null;
                          }),
                        ),
                        const SizedBox(width: 12),
                        _CategoryCard(
                          emoji: '🪑',
                          title: 'Furniture',
                          subtitle: 'Bed, Chair, Door',
                          isSelected: _selectedCategory == 'Furniture',
                          color: const Color(0xFF8B5CF6),
                          bgColor: AppTheme.surfaceDark,
                          onTap: () => setState(() {
                            _selectedCategory = 'Furniture';
                            _selectedIssue = null;
                          }),
                        ),
                      ],
                    ),

                    // ── Issue type ────────────────────────────
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 28),
                      SectionHeader(
                        title: 'What\'s the Issue?',
                        subtitle: 'Select specific problem',
                      ),
                      const SizedBox(height: 14),

                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                        children:
                            _issueMap[_selectedCategory!]!.map((issue) {
                          final selected = _selectedIssue == issue.label;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedIssue = issue.label),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryLight
                                    : AppTheme.surfaceDark,
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primaryOrange
                                      : AppTheme.cardBorder,
                                  width: selected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(issue.emoji,
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(
                                    issue.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: selected
                                          ? AppTheme.primaryOrange
                                          : AppTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Description ────────────────────────────
                    const SectionHeader(
                      title: 'Describe the Issue',
                      subtitle: 'More details = faster fix',
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., The ceiling fan in my room makes a loud grinding noise when switched on. It vibrates a lot...',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Image upload ──────────────────────────
                    const SectionHeader(
                      title: 'Upload Photo',
                      subtitle: 'Optional — helps our team understand the issue',
                    ),
                    const SizedBox(height: 12),

                    ImageUploadTile(
                      label: 'Upload Issue Photo',
                      selectedPath: _imagePath,
                      icon: Icons.camera_alt_rounded,
                      onTap: () => setState(
                          () => _imagePath = '/mock/issue_photo.jpg'),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit ─────────────────────────────────
                    PrimaryButton(
                      label: 'Submit Complaint',
                      onTap: _submit,
                      icon: Icons.send_rounded,
                      color: AppTheme.success,
                    ),

                    const SizedBox(height: 20),

                    // ── Working hours note ─────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Working hours: 9 AM – 6 PM. Requests submitted after 6 PM will be processed the next morning.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.warning,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complaint Submitted!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your $_selectedCategory complaint has been registered.\nExpect resolution within 24 hours.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueItem {
  final String emoji;
  final String label;

  const _IssueItem(this.emoji, this.label);
}

// ── Category card ─────────────────────────
class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : bgColor,
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: color, size: 14),
                    const SizedBox(width: 4),
                    Text('Selected',
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
