// ─────────────────────────────────────────────
//  RoomServicesScreen — Cleaning requests
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class RoomServicesScreen extends StatefulWidget {
  const RoomServicesScreen({super.key});

  @override
  State<RoomServicesScreen> createState() => _RoomServicesScreenState();
}

class _RoomServicesScreenState extends State<RoomServicesScreen> {
  String? _selectedService;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '9:00 AM – 10:00 AM';
  bool _submitted = false;

  final List<String> _timeSlots = [
    '9:00 AM – 10:00 AM',
    '10:00 AM – 11:00 AM',
    '11:00 AM – 12:00 PM',
    '2:00 PM – 3:00 PM',
    '3:00 PM – 4:00 PM',
    '4:00 PM – 5:00 PM',
  ];

  void _submit() {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }
    context.read<AppProvider>().addCleaningRequest(_selectedService!);
    setState(() => _submitted = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Services'),
        backgroundColor: Colors.white,
      ),
      body: _submitted ? _buildSuccessView() : _buildFormView(),
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
              'Request Submitted! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your cleaning request has been received.\nOur team will be there on time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redirecting back...',
              style: TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header banner ──────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Text('🧹', style: TextStyle(fontSize: 40)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Cleaning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Professional cleaning service\nfor your hostel room',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Service selection ─────────────────────
          const SectionHeader(
            title: 'Select Service Type',
            subtitle: 'What kind of cleaning do you need?',
          ),

          const SizedBox(height: 16),

          _ServiceOption(
            emoji: '🧹',
            title: 'Normal Cleaning',
            description: 'Sweeping, dusting, and basic tidying of the room',
            price: 'Free',
            duration: '30–45 min',
            isSelected: _selectedService == 'Normal Cleaning',
            onTap: () => setState(() => _selectedService = 'Normal Cleaning'),
          ),

          const SizedBox(height: 12),

          _ServiceOption(
            emoji: '✨',
            title: 'Deep Cleaning',
            description:
                'Thorough cleaning with mopping, dusting all surfaces, sanitizing',
            price: 'Free',
            duration: '60–90 min',
            isSelected: _selectedService == 'Deep Cleaning',
            onTap: () => setState(() => _selectedService = 'Deep Cleaning'),
          ),

          const SizedBox(height: 28),

          // ── Date selection ────────────────────────
          const SectionHeader(
            title: 'Schedule Date',
            subtitle: 'Choose your preferred date',
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _scheduledDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 14)),
                builder: (ctx, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.primary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _scheduledDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_scheduledDate.day} ${_monthName(_scheduledDate.month)} ${_scheduledDate.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_rounded,
                      color: AppTheme.textLight, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Time slot ─────────────────────────────
          const SectionHeader(
            title: 'Preferred Time Slot',
            subtitle: 'Select a convenient time',
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final selected = _selectedTimeSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedTimeSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppTheme.textMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Notes ────────────────────────────────
          const SectionHeader(
            title: 'Additional Notes',
            subtitle: 'Optional',
          ),
          const SizedBox(height: 12),
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'e.g., Please don\'t move the items on my desk...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Submit Request',
            onTap: _submit,
            icon: Icons.send_rounded,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// ── Service option card ───────────────────
class _ServiceOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String price;
  final String duration;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceOption({
    required this.emoji,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMedium,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tag(Icons.access_time_rounded, duration),
                      const SizedBox(width: 8),
                      _tag(Icons.currency_rupee_rounded, price),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppTheme.textMedium),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
