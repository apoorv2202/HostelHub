// ─────────────────────────────────────────────
//  RegistrationScreen — Complete profile setup
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../main_scaffold.dart';
import '../../services/squidex_service.dart';
import '../../models/models.dart';

class RegistrationScreen extends StatefulWidget {
  final String phone;

  const RegistrationScreen({super.key, required this.phone});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  String? _selectedCollege;
  String? _selectedHostel;
  String? _messCardPath;
  String? _idCardPath;

  List<CollegeModel> _colleges = [];
  List<HostelModel> _allHostels = [];
  bool _isLoadingData = true;

  CollegeModel? _selectedCollegeModel;

  List<String> get _hostels {
    if (_selectedCollegeModel == null) return [];
    return _allHostels
        .where((h) => h.collegeId == _selectedCollegeModel!.id)
        .map((h) => h.name)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final squidex = SquidexService();
      final colleges = await squidex.getColleges();
      final hostels = await squidex.getHostels();
      
      if (mounted) {
        setState(() {
          _colleges = colleges;
          _allHostels = hostels;
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
    _roomCtrl.dispose();
    super.dispose();
  }

  // ── Simulate image picker ─────────────────
  Future<void> _pickImage(bool isMessCard) async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      if (isMessCard) {
        _messCardPath = '/mock/mess_card.jpg';
      } else {
        _idCardPath = '/mock/id_card.jpg';
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMessCard ? 'Mess Card selected ✓' : 'ID Card selected ✓'),
          backgroundColor: AppTheme.success,
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
    if (_selectedHostel == null) {
      _showError('Please select your hostel');
      return;
    }

    final provider = context.read<AppProvider>();
    await provider.register(
      name: _nameCtrl.text.trim(),
      phone: widget.phone,
      college: _selectedCollege!,
      hostel: _selectedHostel!,
      roomNumber: _roomCtrl.text.trim(),
      messCardPath: _messCardPath,
      idCardPath: _idCardPath,
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (_) => false,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: AppTheme.bg,
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Progress indicator ─────────────────────
                _buildProgressBar(),

                const SizedBox(height: 28),

                // ── Step 1 heading ─────────────────────────
                _buildStepHeader('1', 'Personal Details'),

                const SizedBox(height: 20),

                // ── Name ──────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: 'Rahul Sharma',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter your name' : null,
                ),

                const SizedBox(height: 16),

                // ── Phone (read-only) ─────────────────────
                TextFormField(
                  initialValue: '+91 ${widget.phone}',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: Color(0xFFF9FAFB),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Step 2 heading ─────────────────────────
                _buildStepHeader('2', 'Hostel Details'),

                const SizedBox(height: 20),

                // ── College dropdown ──────────────────────
                _isLoadingData 
                ? const Center(child: CircularProgressIndicator()) 
                : DropdownButtonFormField<String>(
                  value: _selectedCollege,
                  decoration: const InputDecoration(
                    labelText: 'College',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  hint: const Text('Select your college'),
                  isExpanded: true,
                  items: _colleges
                      .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    _selectedCollege = val;
                    _selectedCollegeModel = _colleges.firstWhere((c) => c.name == val);
                    _selectedHostel = null; // reset hostel
                  }),
                  validator: (v) =>
                      v == null ? 'Please select a college' : null,
                ),

                const SizedBox(height: 16),

                // ── Hostel dropdown ───────────────────────
                _isLoadingData
                ? const SizedBox.shrink()
                : DropdownButtonFormField<String>(
                  value: _selectedHostel,
                  decoration: InputDecoration(
                    labelText: 'Hostel',
                    prefixIcon: const Icon(Icons.apartment_outlined),
                    filled: true,
                    fillColor: _selectedCollege == null
                        ? const Color(0xFFF3F4F6)
                        : Colors.white,
                  ),
                  hint: Text(
                    _selectedCollege == null
                        ? 'Select college first'
                        : 'Select your hostel',
                  ),
                  isExpanded: true,
                  items: _hostels
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: _selectedCollege == null
                      ? null
                      : (val) => setState(() => _selectedHostel = val),
                  validator: (v) =>
                      v == null ? 'Please select a hostel' : null,
                ),

                const SizedBox(height: 16),

                // ── Room number ───────────────────────────
                TextFormField(
                  controller: _roomCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Room Number',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    hintText: 'e.g., A-204',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your room number'
                      : null,
                ),

                const SizedBox(height: 28),

                // ── Step 3 heading ─────────────────────────
                _buildStepHeader('3', 'Upload Documents'),

                const SizedBox(height: 8),
                const Text(
                  'Upload your cards for verification. You can skip and upload later.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Mess Card upload ──────────────────────
                ImageUploadTile(
                  label: 'Mess Card',
                  selectedPath: _messCardPath,
                  icon: Icons.credit_card_rounded,
                  onTap: () => _pickImage(true),
                ),

                const SizedBox(height: 12),

                // ── ID Card upload ────────────────────────
                ImageUploadTile(
                  label: 'College ID Card',
                  selectedPath: _idCardPath,
                  icon: Icons.badge_rounded,
                  onTap: () => _pickImage(false),
                ),

                const SizedBox(height: 32),

                // ── Submit button ─────────────────────────
                PrimaryButton(
                  label: 'Create Account',
                  onTap: _register,
                  isLoading: isLoading,
                  icon: Icons.arrow_forward_rounded,
                ),

                const SizedBox(height: 12),

                // ── Terms ─────────────────────────────────
                const Center(
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step header widget ────────────────────
  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Progress bar ──────────────────────────
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profile Setup',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            Text(
              '${_getProgress()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _getProgress() / 100,
            backgroundColor: AppTheme.primaryLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  int _getProgress() {
    int progress = 0;
    if (_nameCtrl.text.isNotEmpty) progress += 20;
    if (_selectedCollege != null) progress += 20;
    if (_selectedHostel != null) progress += 20;
    if (_roomCtrl.text.isNotEmpty) progress += 20;
    if (_messCardPath != null || _idCardPath != null) progress += 20;
    return progress;
  }
}
