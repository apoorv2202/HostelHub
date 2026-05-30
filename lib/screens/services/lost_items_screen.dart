// ─────────────────────────────────────────────
//  LostItemsScreen — Report lost items & pay
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LostItemsScreen extends StatefulWidget {
  const LostItemsScreen({super.key});

  @override
  State<LostItemsScreen> createState() => _LostItemsScreenState();
}

class _LostItemsScreenState extends State<LostItemsScreen> {
  String? _selectedItem;
  bool _isProcessing = false;
  bool _paymentDone = false;

  final List<_LostItemData> _items = [
    _LostItemData(
      emoji: '💳',
      title: 'Mess Card',
      description: 'Lost or damaged mess card replacement',
      baseFee: 500,
      processingFee: 50,
      color: const Color(0xFF6366F1),
      bgColor: const Color(0xFFEEF2FF),
      steps: [
        'Fill this form and pay the fee',
        'Verification by hostel warden',
        'New card issued within 2–3 days',
      ],
    ),
    _LostItemData(
      emoji: '🪪',
      title: 'ID Card',
      description: 'Lost or damaged college ID card replacement',
      baseFee: 500,
      processingFee: 100,
      color: const Color(0xFF10B981),
      bgColor: const Color(0xFFECFDF5),
      steps: [
        'Fill this form and pay the fee',
        'FIR copy required (if lost)',
        'New ID issued within 5–7 days',
      ],
    ),
    _LostItemData(
      emoji: '🔑',
      title: 'Room Keys',
      description: 'Lost room key or duplicate key request',
      baseFee: 300,
      processingFee: 50,
      color: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFFFBEB),
      steps: [
        'Fill this form and pay the fee',
        'Warden approval required',
        'New key issued same day',
      ],
    ),
  ];

  _LostItemData? get _selected =>
      _selectedItem == null
          ? null
          : _items.firstWhere((i) => i.title == _selectedItem);

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId != null) {
        final itemType = _selectedItem == 'Mess Card' ? 'mess_card' : 'id_card';
        
        await supabase.from('lost_requests').insert({
          'user_id': userId,
          'item_type': itemType,
          'payment_status': 'paid',
          'status': 'pending',
        });
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _paymentDone = true;
        });
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Lost Items 🔑'),
        backgroundColor: AppTheme.bg,
      ),
      body: _paymentDone
          ? _buildSuccessView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Alert banner ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.warning, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Notice',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.warning,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Lost item fees are non-refundable. Please check your room thoroughly before applying.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.warning,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SectionHeader(
                    title: 'What did you lose?',
                    subtitle: 'Select the item to report',
                  ),

                  const SizedBox(height: 16),

                  // ── Item cards ────────────────────────────
                  ..._items.map((item) => _LostItemCard(
                        data: item,
                        isSelected: _selectedItem == item.title,
                        onTap: () =>
                            setState(() => _selectedItem = item.title),
                      )),

                  // ── Fee breakdown + pay ───────────────────
                  if (_selected != null) ...[
                    const SizedBox(height: 24),
                    _buildFeeBreakdown(_selected!),
                    const SizedBox(height: 16),
                    _buildSteps(_selected!),
                    const SizedBox(height: 28),

                    // ── Pay button ─────────────────────────
                    LoadingOverlay(
                      isLoading: _isProcessing,
                      child: PrimaryButton(
                        label:
                            'Pay ₹${(_selected!.baseFee + _selected!.processingFee).toStringAsFixed(0)}  →  Proceed',
                        onTap: _pay,
                        isLoading: _isProcessing,
                        color: _selected!.color,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Secure payment via UPI / Card / Net Banking',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ),

                    // ── Payment methods ─────────────────────
                    const SizedBox(height: 16),
                    _buildPaymentMethods(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildFeeBreakdown(_LostItemData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _FeeRow('${item.title} Replacement Fee',
              '₹${item.baseFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _FeeRow('Processing Fee',
              '₹${item.processingFee.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 0),
          ),
          _FeeRow(
            'Total Amount',
            '₹${(item.baseFee + item.processingFee).toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(_LostItemData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: item.color,
            ),
          ),
          const SizedBox(height: 10),
          ...item.steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.color,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accepted Payment Methods',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _payTag('📱', 'UPI'),
              const SizedBox(width: 8),
              _payTag('💳', 'Debit Card'),
              const SizedBox(width: 8),
              _payTag('🏦', 'Net Banking'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payTag(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textMedium),
          ),
        ],
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
            const Text('✅', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your ${_selected?.title ?? 'item'} replacement request has been submitted.\nYou will be notified once processed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Back to Home',
              onTap: () => Navigator.pop(context),
              icon: Icons.home_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lost Item Card ────────────────────────
class _LostItemCard extends StatelessWidget {
  final _LostItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _LostItemCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? data.color.withOpacity(0.12) : AppTheme.surfaceDark,
          border: Border.all(
            color: isSelected ? data.color : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(data.emoji,
                      style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected ? data.color : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: data.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹${(data.baseFee + data.processingFee).toStringAsFixed(0)} total',
                          style: TextStyle(
                            color: data.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: data.title,
              groupValue: isSelected ? data.title : null,
              onChanged: (_) => onTap(),
              activeColor: data.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _LostItemData {
  final String emoji;
  final String title;
  final String description;
  final double baseFee;
  final double processingFee;
  final Color color;
  final Color bgColor;
  final List<String> steps;

  const _LostItemData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.baseFee,
    required this.processingFee,
    required this.color,
    required this.bgColor,
    required this.steps,
  });
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _FeeRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              color:
                  isBold ? AppTheme.textDark : AppTheme.textMedium,
              fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              color: isBold ? AppTheme.primary : AppTheme.textDark,
              fontWeight:
                  isBold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}
