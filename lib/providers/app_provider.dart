// ─────────────────────────────────────────────
//  AppProvider — App-wide state management
// ─────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Auth state ────────────────────────────
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentPhone;

  UserModel? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  // ── Requests ──────────────────────────────
  List<RequestModel> _requests = [];
  List<RequestModel> get requests => _requests;

  List<RequestModel> get cleaningRequests =>
      _requests.where((r) => r.type == RequestType.cleaning).toList();

  List<RequestModel> get maintenanceRequests =>
      _requests.where((r) => r.type == RequestType.maintenance).toList();

  // ── Orders ────────────────────────────────
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  AppProvider() {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _isLoggedIn = true;
      await _fetchUserProfile();
      _fetchRequests();
      _fetchOrders();
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase.from('profiles').select().eq('uuid', userId).maybeSingle();
      if (response != null) {
        _user = UserModel(
          name: response['name'],
          phone: response['phone'],
          college: response['college'],
          hostel: response['hostel'],
          roomNumber: response['room_number'],
          verificationStatus: VerificationStatus.values.firstWhere((e) => e.name == response['verification_status'], orElse: () => VerificationStatus.pending),
          messCardPath: response['mess_card_path'],
          idCardPath: response['id_card_path'],
        );
      }
    } catch (e) {
      print('Error fetching profile: \$e');
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('requests').select().eq('user_id', userId).order('created_at', ascending: false);
      _requests = (data as List).map((e) => RequestModel(
        id: e['id'].toString(),
        type: e['type'] == 'cleaning' ? RequestType.cleaning : RequestType.maintenance,
        title: e['title'],
        description: e['description'],
        status: RequestStatus.values.firstWhere((st) => st.name == e['status'], orElse: () => RequestStatus.pending),
        createdAt: DateTime.parse(e['created_at']),
        completedAt: e['completed_at'] != null ? DateTime.parse(e['completed_at']) : null,
        category: e['category'],
        imagePath: e['image_path'],
      )).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching requests: \$e');
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('orders').select().eq('user_id', userId).order('created_at', ascending: false);
      _orders = (data as List).map((e) => OrderModel(
        id: e['id'].toString(),
        items: (e['items'] as List).map((i) => OrderItem(
          name: i['name'],
          quantity: i['quantity'],
          price: (i['price'] as num).toDouble(),
        )).toList(),
        status: OrderStatus.values.firstWhere((st) => st.name == e['status'], orElse: () => OrderStatus.preparing),
        createdAt: DateTime.parse(e['created_at']),
        total: (e['total'] as num).toDouble(),
      )).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: \$e');
    }
  }

  // ── Send OTP ─────────────────────────────
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentPhone = phone.startsWith('+') ? phone : '+91$phone'; // assuming India +91 as default
      
      if (_currentPhone == '+919876543210') {
        _setLoading(false);
        return true; // Bypass for test number
      }

      await _supabase.auth.signInWithOtp(phone: _currentPhone!);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Verify OTP ───────────────────────────
  Future<bool> verifyOtp(String otp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (_currentPhone == '+919876543210' && otp == '123456') {
        // Bypass Supabase OTP bug: Log in with a dummy email instead
        final response = await _supabase.auth.signInWithPassword(
          email: 'test@hostelhub.com',
          password: 'testpassword123',
        );
        if (response.session != null) {
          _isLoggedIn = true;
          await _fetchUserProfile();
          _fetchRequests();
          _fetchOrders();
          _setLoading(false);
          return true;
        }
        return false;
      }

      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: _currentPhone!,
      );
      if (response.session != null) {
        _isLoggedIn = true;
        await _fetchUserProfile();
        _fetchRequests();
        _fetchOrders();
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Complete registration ─────────────────
  Future<void> register({
    required String name,
    required String phone,
    required String college,
    required String hostel,
    required String roomNumber,
    String? messCardPath,
    String? idCardPath,
  }) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').upsert({
        'uuid': userId,
        'name': name,
        'phone': phone,
        'college': college,
        'hostel': hostel,
        'room_number': roomNumber,
        'verification_status': 'pending',
        'mess_card_path': messCardPath,
        'id_card_path': idCardPath,
      });

      _user = UserModel(
        name: name,
        phone: phone,
        college: college,
        hostel: hostel,
        roomNumber: roomNumber,
        verificationStatus: VerificationStatus.pending,
        messCardPath: messCardPath,
        idCardPath: idCardPath,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  // ── Add cleaning request ──────────────────
  Future<void> addCleaningRequest(String type) async {
    final req = {
      'user_id': _supabase.auth.currentUser!.id,
      'type': 'cleaning',
      'title': type,
      'description': type == 'Deep Cleaning'
          ? 'Full room deep cleaning with mopping'
          : 'Regular sweep and dusting',
      'status': 'pending',
    };
    await _supabase.from('requests').insert(req);
    await _fetchRequests();
  }

  // ── Add maintenance request ───────────────
  Future<void> addMaintenanceRequest({
    required String category,
    required String description,
    String? imagePath,
  }) async {
    final req = {
      'user_id': _supabase.auth.currentUser!.id,
      'type': 'maintenance',
      'title': '\$category Issue',
      'description': description,
      'category': category,
      'image_path': imagePath,
      'status': 'pending',
    };
    await _supabase.from('requests').insert(req);
    await _fetchRequests();
  }

  // ── Add order (from cart) ─────────────────
  Future<void> addOrder(List<OrderItem> items, double total) async {
    final order = {
      'user_id': _supabase.auth.currentUser!.id,
      'items': items.map((i) => {
        'name': i.name,
        'quantity': i.quantity,
        'price': i.price,
      }).toList(),
      'status': 'preparing',
      'total': total,
    };
    await _supabase.from('orders').insert(order);
    await _fetchOrders();
  }

  // ── Logout ────────────────────────────────
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    _isLoggedIn = false;
    _requests.clear();
    _orders.clear();
    notifyListeners();
  }

  // ── Helper ────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}

