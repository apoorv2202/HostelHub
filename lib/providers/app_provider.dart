// lib/providers/app_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/user.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../services/squidex_service.dart';

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
      
      // Auto-correct the 9876543210 student role if it was accidentally set to admin
      final checkResp = await _supabase.from('profiles').select('phone, role').eq('id', userId).maybeSingle();
      if (checkResp != null && checkResp['phone'] == '+919876543210' && checkResp['role'] == 'admin') {
        await _supabase.from('profiles').update({'role': 'student'}).eq('id', userId);
        print('🔧 Automatically corrected 9876543210 profile role from admin to student!');
      }

      final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
      if (response != null) {
        final roleStr = response['role'];
        final isMaintenance = response['hostel'] == 'Maintenance' || response['room_number'] == 'Maintenance';

        _user = UserModel(
          name: response['name'],
          phone: response['phone'],
          college: response['college'],
          hostel: response['hostel'] ?? '',
          roomNumber: response['room_number'] ?? '',
          role: isMaintenance 
              ? UserRole.maintenance 
              : (roleStr == 'warden' || roleStr == 'admin' 
                  ? UserRole.warden 
                  : (roleStr == 'cleaner' 
                      ? UserRole.cleaning 
                      : (roleStr == 'canteen' 
                          ? UserRole.canteen 
                          : UserRole.student))),
          verificationStatus: VerificationStatus.values.firstWhere(
              (e) => e.name == response['verification_status'], 
              orElse: () => VerificationStatus.pending
          ),
          messCardPath: response['mess_card_path'],
          idCardPath: response['id_card_path'],
        );
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      var serviceQuery = _supabase.from('service_requests').select();
      var maintenanceQuery = _supabase.from('maintenance_requests').select();

      if (_user?.role == UserRole.student && userId != null) {
        serviceQuery = serviceQuery.eq('user_id', userId);
        maintenanceQuery = maintenanceQuery.eq('user_id', userId);
      }

      final serviceData = await serviceQuery.order('created_at', ascending: false);
      final maintenanceData = await maintenanceQuery.order('created_at', ascending: false);

      final List<RequestModel> fetchedRequests = [];

      // Map service requests
      fetchedRequests.addAll((serviceData as List).map((e) => RequestModel(
        id: e['id'].toString(),
        type: RequestType.cleaning,
        title: e['cleaning_type'] == 'deep_cleaning' ? 'Deep Cleaning' : 'Normal Cleaning',
        description: e['description'] ?? '',
        status: RequestStatus.values.firstWhere((st) => st.name == e['status'], orElse: () => RequestStatus.pending),
        createdAt: DateTime.parse(e['created_at']),
        completedAt: e['completed_at'] != null ? DateTime.parse(e['completed_at']) : null,
        category: 'Cleaning',
        imagePath: null,
      )));

      // Map maintenance requests
      fetchedRequests.addAll((maintenanceData as List).map((e) => RequestModel(
        id: e['id'].toString(),
        type: RequestType.maintenance,
        title: '${e['category'] != null ? e['category'][0].toUpperCase() + e['category'].substring(1) : "Maintenance"} Issue',
        description: e['description'] ?? '',
        status: RequestStatus.values.firstWhere((st) => st.name == e['status'], orElse: () => RequestStatus.pending),
        createdAt: DateTime.parse(e['created_at']),
        completedAt: e['completed_at'] != null ? DateTime.parse(e['completed_at']) : null,
        category: e['category'],
        imagePath: (e['image_urls'] as List?)?.isNotEmpty == true 
            ? (e['image_urls'] as List).first.toString() 
            : null,
      )));

      // Sort combined list by created_at descending
      fetchedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _requests = fetchedRequests;
      
      notifyListeners();
    } catch (e) {
      print('Error fetching requests: $e');
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      var query = _supabase.from('orders').select();

      if (_user?.role == UserRole.student && userId != null) {
        query = query.eq('user_id', userId);
      } else if (_user?.role == UserRole.canteen) {
        query = query.eq('college', _user?.college ?? '');
      }

      final data = await query.order('created_at', ascending: false);
      _orders = (data as List).map((e) {
        // Map DB order_status strings to Flutter OrderStatus enum
        OrderStatus mappedStatus;
        switch (e['order_status']) {
          case 'pending':
            mappedStatus = OrderStatus.placed;
            break;
          case 'accepted':
          case 'preparing':
            mappedStatus = OrderStatus.preparing;
            break;
          case 'ready':
            mappedStatus = OrderStatus.outForDelivery;
            break;
          case 'completed':
            mappedStatus = OrderStatus.delivered;
            break;
          default:
            mappedStatus = OrderStatus.placed;
        }
        return OrderModel(
          id: e['id'].toString(),
          items: (e['items'] as List).map((i) => OrderItem(
            name: i['name'],
            quantity: i['quantity'],
            price: (i['price'] as num).toDouble(),
          )).toList(),
          status: mappedStatus,
          createdAt: DateTime.parse(e['created_at']),
          total: (e['total_price'] as num).toDouble(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  // ── Complete Staff registration ───────────
  Future<bool> registerStaff({
    required String name,
    required String phone,
    required String college,
    required String staffId,
    required UserRole role,
    String? idCardPath,
  }) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Handle Storage Upload for private user_cards bucket
      String? remoteIdPath;
      if (!kIsWeb && idCardPath != null && !idCardPath.startsWith('http') && !idCardPath.startsWith('user_cards/')) {
        final file = File(idCardPath);
        if (await file.exists()) {
          final fileExt = idCardPath.split('.').last;
          final storagePath = '$userId/id_card.$fileExt';
          
          await _supabase.storage.from('user_cards').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
          remoteIdPath = storagePath;
        }
      } else {
        remoteIdPath = idCardPath;
      }

      // Map role to DB scope
      String dbRoleStr = role.dbRoleValue;
      String hostelStr = '';
      String roomNumberStr = staffId; // Store Staff ID in room_number

      if (role == UserRole.maintenance) {
        dbRoleStr = 'warden';
        hostelStr = 'Maintenance'; // Flag used to identify maintenance role
        roomNumberStr = staffId;
      }

      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final isWarden = role == UserRole.warden || cleanPhone.endsWith('9876543211');
      final dbStatus = isWarden ? 'verified' : 'pending';
      final modelStatus = isWarden ? VerificationStatus.verified : VerificationStatus.pending;

      await _supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'phone': phone,
        'college': college,
        'hostel': hostelStr,
        'room_number': roomNumberStr,
        'role': dbRoleStr,
        'verification_status': dbStatus,
        'id_card_path': remoteIdPath ?? '',
      });

      _user = UserModel(
        name: name,
        phone: phone,
        college: college,
        hostel: hostelStr,
        roomNumber: roomNumberStr,
        role: role,
        verificationStatus: modelStatus,
        messCardPath: null,
        idCardPath: remoteIdPath,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Send OTP ─────────────────────────────
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _currentPhone = phone.startsWith('+') ? phone : '+91$phone';
      
      final mockNumbers = [
        '+919876543210', // Student
        '+919876543211', // Warden
        '+919876543212', // Canteen
        '+919876543213', // Cleaner
        '+919876543214', // Maintenance
      ];

      if (mockNumbers.contains(_currentPhone)) {
        _setLoading(false);
        return true; // Bypass for test numbers
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
      final mockMappings = {
        '+919876543210': 'student@hostelhub.com',
        '+919876543211': 'warden@hostelhub.com',
        '+919876543212': 'canteen@hostelhub.com',
        '+919876543213': 'cleaner@hostelhub.com',
        '+919876543214': 'maintenance@hostelhub.com',
      };

      if (mockMappings.containsKey(_currentPhone) && otp == '123456') {
        final email = mockMappings[_currentPhone]!;
        AuthResponse response;
        try {
          response = await _supabase.auth.signInWithPassword(
            email: email,
            password: 'testpassword123',
          );
        } catch (e) {
          try {
            response = await _supabase.auth.signUp(
              email: email,
              password: 'testpassword123',
            );
          } catch (signUpErr) {
            _errorMessage = "Auth Error: ${signUpErr.toString()}";
            _setLoading(false);
            return false;
          }
        }

        if (response.session != null) {
          _isLoggedIn = true;
          await _fetchUserProfile();
          await _fetchRequests();
          await _fetchOrders();
          _setLoading(false);
          return true;
        } else {
          _errorMessage = "Confirmation required for $email. Please disable 'Confirm Email' in Supabase Auth settings or manually create this user in Supabase Auth tab.";
          _setLoading(false);
          return false;
        }
      }

      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: _currentPhone!,
      );
      if (response.session != null) {
        _isLoggedIn = true;
        await _fetchUserProfile();
        await _fetchRequests();
        await _fetchOrders();
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Complete student registration ─────────
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

      // Handle Storage Upload for private user_cards bucket
      String? remoteIdPath;
      String? remoteMessPath;

      if (!kIsWeb && idCardPath != null && !idCardPath.startsWith('http') && !idCardPath.startsWith('user_cards/')) {
        final file = File(idCardPath);
        if (await file.exists()) {
          final fileExt = idCardPath.split('.').last;
          final storagePath = '$userId/id_card.$fileExt';
          
          await _supabase.storage.from('user_cards').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
          remoteIdPath = storagePath;
        }
      } else {
        remoteIdPath = idCardPath;
      }

      if (!kIsWeb && messCardPath != null && !messCardPath.startsWith('http') && !messCardPath.startsWith('user_cards/')) {
        final file = File(messCardPath);
        if (await file.exists()) {
          final fileExt = messCardPath.split('.').last;
          final storagePath = '$userId/mess_card.$fileExt';
          
          await _supabase.storage.from('user_cards').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
          remoteMessPath = storagePath;
        }
      } else {
        remoteMessPath = messCardPath;
      }

      await _supabase.from('profiles').upsert({
        'id': userId,
        'name': name,
        'phone': phone,
        'college': college,
        'hostel': hostel,
        'room_number': roomNumber,
        'role': 'student',
        'verification_status': 'pending',
        'mess_card_path': remoteMessPath,
        'id_card_path': remoteIdPath!,
      });

      _user = UserModel(
        name: name,
        phone: phone,
        college: college,
        hostel: hostel,
        roomNumber: roomNumber,
        role: UserRole.student,
        verificationStatus: VerificationStatus.pending,
        messCardPath: remoteMessPath,
        idCardPath: remoteIdPath,
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
      'cleaning_type': type == 'Deep Cleaning' ? 'deep_cleaning' : 'normal_cleaning',
      'description': type == 'Deep Cleaning'
          ? 'Full room deep cleaning with mopping'
          : 'Regular sweep and dusting',
      'status': 'pending',
    };
    await _supabase.from('service_requests').insert(req);
    await _fetchRequests();
  }

  // ── Add maintenance request ───────────────
  Future<void> addMaintenanceRequest({
    required String category,
    required String description,
    String? imagePath,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    List<String> remoteImageUrls = [];

    // Handle Storage Upload for private maintenance_images bucket
    if (!kIsWeb && imagePath != null && !imagePath.startsWith('http') && !imagePath.startsWith('maintenance_images/')) {
      final file = File(imagePath);
      if (await file.exists()) {
        final fileExt = imagePath.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final storagePath = '$userId/$fileName';
        
        await _supabase.storage.from('maintenance_images').upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        remoteImageUrls.add(storagePath);
      }
    }

    final categoryLower = category.toLowerCase();
    final validCategory = (categoryLower == 'electrician' || categoryLower == 'furniture') 
        ? categoryLower 
        : 'electrician';

    final req = {
      'user_id': userId,
      'category': validCategory,
      'description': description,
      'image_urls': remoteImageUrls,
      'status': 'pending',
    };
    await _supabase.from('maintenance_requests').insert(req);
    await _fetchRequests();
  }

  // ── Add order (from cart) ─────────────────
  Future<void> addOrder(List<OrderItem> items, double total) async {
    final order = {
      'user_id': _supabase.auth.currentUser!.id,
      'college': _user?.college ?? 'RV',
      'items': items.map((i) => {
        'name': i.name,
        'quantity': i.quantity,
        'price': i.price,
      }).toList(),
      'payment_status': 'pending',
      'order_status': 'pending',
      'total_price': total,
    };
    await _supabase.from('orders').insert(order);
    await _fetchOrders();
  }

  // ── Food Items State & Stock Toggle ────────
  List<FoodItem> _foodItems = [];
  List<FoodItem> get foodItems => _foodItems;

  Future<void> fetchFoodItems() async {
    try {
      final items = await SquidexService().getFoodItems();
      if (items.isNotEmpty) {
        _foodItems = items;
      } else if (_foodItems.isEmpty) {
        _foodItems = _getFallbackFoodItems();
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching food items: $e');
      if (_foodItems.isEmpty) {
        _foodItems = _getFallbackFoodItems();
        notifyListeners();
      }
    }
  }

  void toggleFoodAvailability(String id) {
    final idx = _foodItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _foodItems[idx];
      _foodItems[idx] = FoodItem(
        id: old.id,
        name: old.name,
        price: old.price,
        isVeg: old.isVeg,
        isAvailable: !old.isAvailable,
        category: old.category,
        emoji: old.emoji,
        description: old.description,
      );
      notifyListeners();
    }
  }

  List<FoodItem> _getFallbackFoodItems() {
    return [
      FoodItem(
        id: '1',
        name: 'Crispy Veg Burger',
        price: 89.0,
        isVeg: true,
        isAvailable: true,
        category: 'Burger',
        emoji: '🍔',
        description: 'Delicious crispy veg patty burger with cheese and lettuce.',
      ),
      FoodItem(
        id: '2',
        name: 'Masala Sandwich',
        price: 59.0,
        isVeg: true,
        isAvailable: true,
        category: 'Sandwich',
        emoji: '🥪',
        description: 'Classic toasted masala sandwich with spicy green chutney.',
      ),
      FoodItem(
        id: '3',
        name: 'Paneer Roll',
        price: 99.0,
        isVeg: true,
        isAvailable: true,
        category: 'Rolls',
        emoji: '🌯',
        description: 'Soft paneer tikka wrapped in a warm flaky paratha.',
      ),
      FoodItem(
        id: '4',
        name: 'Double Egg Roll',
        price: 79.0,
        isVeg: false,
        isAvailable: true,
        category: 'Rolls',
        emoji: '🌯',
        description: 'Double egg omelette wrapper loaded with onion and sauces.',
      ),
      FoodItem(
        id: '5',
        name: 'French Fries',
        price: 69.0,
        isVeg: true,
        isAvailable: true,
        category: 'Snacks',
        emoji: '🍟',
        description: 'Golden salted potato fries served with tomato ketchup.',
      ),
      FoodItem(
        id: '6',
        name: 'Oreo Milkshake',
        price: 79.0,
        isVeg: true,
        isAvailable: true,
        category: 'Beverages',
        emoji: '🥤',
        description: 'Creamy cold chocolate milkshake blended with Oreo cookies.',
      ),
    ];
  }

  // ── Logout ────────────────────────────────
  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    _requests.clear();
    _orders.clear();
    notifyListeners();

    // Fire-and-forget inside a microtask, ensuring no trace of network blocking in the current frame
    Future.microtask(() async {
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        print('Background signout error: $e');
      }
    });
  }

  // ── Helper ────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await _fetchOrders();
  }

  Future<void> refreshRequests() async {
    await _fetchRequests();
  }
}
