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

  // ── Announcements ─────────────────────────
  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;
  RealtimeChannel? _announcementsChannel;
  RealtimeChannel? _foodStockChannel;
  RealtimeChannel? _requestsChannel;

  // ── Requests ──────────────────────────────
  List<RequestModel> _requests = [];
  List<RequestModel> get requests => _requests;

  List<RequestModel> get cleaningRequests =>
      _requests.where((r) => r.type == RequestType.cleaning).toList();

  List<RequestModel> get maintenanceRequests =>
      _requests.where((r) => r.type == RequestType.maintenance).toList();

  List<RequestModel> get lostItemRequests =>
      _requests.where((r) => r.type == RequestType.lostItem).toList();


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
      // Fetch announcements and subscribe to real-time updates
      await fetchAnnouncements();
      _subscribeToAnnouncements();
      _subscribeToFoodStock();
      _subscribeToRequests();
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      var serviceQuery = _supabase.from('service_requests').select();
      var maintenanceQuery = _supabase.from('maintenance_requests').select();
      var lostQuery = _supabase.from('lost_requests').select();

      if (_user?.role == UserRole.student && userId != null) {
        serviceQuery = serviceQuery.eq('user_id', userId);
        maintenanceQuery = maintenanceQuery.eq('user_id', userId);
        lostQuery = lostQuery.eq('user_id', userId);
      }

      final serviceData = await serviceQuery.order('created_at', ascending: false);
      final maintenanceData = await maintenanceQuery.order('created_at', ascending: false);
      final lostData = await lostQuery.order('created_at', ascending: false);

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

      // Map lost requests
      fetchedRequests.addAll((lostData as List).map((e) {
        String title = 'Lost Card';
        if (e['item_type'] == 'mess_card') {
          title = 'Lost Mess Card';
        } else if (e['item_type'] == 'id_card') {
          title = 'Lost ID Card';
        } else if (e['item_type'] == 'room_keys') {
          title = 'Lost Room Keys';
        }
        return RequestModel(
          id: e['id'].toString(),
          type: RequestType.lostItem,
          title: title,
          description: 'Payment Status: ${e['payment_status']}',
          status: e['status'] == 'approved' 
              ? RequestStatus.inProgress 
              : (e['status'] == 'completed' 
                  ? RequestStatus.completed 
                  : (e['status'] == 'rejected' 
                      ? RequestStatus.rejected 
                      : RequestStatus.pending)),
          createdAt: DateTime.parse(e['created_at']),
          completedAt: null,
          category: 'Lost Request',
          imagePath: null,
        );
      }));

      // Sort combined list by created_at descending
      fetchedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _requests = fetchedRequests;
      
      notifyListeners();
    } catch (e) {
      print('Error fetching requests: $e');
    }
  }

  // ── Add Lost Card/Key request ─────────────────
  Future<void> addLostRequest(String itemType) async {
    try {
      String dbItemType = 'mess_card';
      if (itemType == 'ID Card') {
        dbItemType = 'id_card';
      } else if (itemType == 'Room Keys' || itemType == 'Keys') {
        dbItemType = 'room_keys';
      }

      final req = {
        'user_id': _supabase.auth.currentUser!.id,
        'item_type': dbItemType,
        'payment_status': 'paid',
        'status': 'pending',
      };
      await _supabase.from('lost_requests').insert(req);
      await _fetchRequests();
    } catch (e) {
      print('Error adding lost request: $e');
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

  // ── Login with ID Card ────────────────────
  Future<bool> loginWithIdCard(String id, UserRole role) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final matchingUser = demoUsers.firstWhere(
        (u) => u.id.toLowerCase() == id.toLowerCase(),
        orElse: () => const DemoUser(phone: '', role: '', college: '', hostel: '', id: '', room: ''),
      );

      if (matchingUser.phone.isEmpty) {
        _errorMessage = 'Invalid ID. Please check your credentials.';
        _setLoading(false);
        return false;
      }

      // Check role mapping
      String mappedRoleStr = matchingUser.role;
      bool roleMatches = false;
      if (role == UserRole.student && mappedRoleStr == 'student') roleMatches = true;
      if (role == UserRole.warden && mappedRoleStr == 'warden') roleMatches = true;
      if (role == UserRole.cleaning && mappedRoleStr == 'cleaner') roleMatches = true;
      if (role == UserRole.canteen && mappedRoleStr == 'canteen') roleMatches = true;
      if (role == UserRole.maintenance && mappedRoleStr == 'maintenance') roleMatches = true;

      if (!roleMatches) {
        _errorMessage = 'This ID is registered under a different role.';
        _setLoading(false);
        return false;
      }

      // Log in using password authentication (similar to verifyOtp)
      final email = 'user_${matchingUser.phone}@hostelhub.com';
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
        
        // Auto-create/upsert profile if it doesn't exist
        final userId = response.user!.id;
        final profileCheck = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
        if (profileCheck == null) {
          // Auto register warden as verified, others as pending
          final isWarden = role == UserRole.warden;
          final statusStr = isWarden ? 'verified' : 'pending';
          
          String dbRoleStr = role.dbRoleValue;
          String hostelStr = matchingUser.hostel;
          String roomNumberStr = matchingUser.room;
          
          if (role == UserRole.maintenance) {
            dbRoleStr = 'warden';
            hostelStr = 'Maintenance';
            roomNumberStr = matchingUser.id;
          } else if (role == UserRole.cleaning) {
            hostelStr = '';
            roomNumberStr = matchingUser.id;
          } else if (role == UserRole.canteen) {
            hostelStr = '';
            roomNumberStr = matchingUser.id;
          } else if (role == UserRole.warden) {
            hostelStr = '';
            roomNumberStr = matchingUser.id;
          }

          await _supabase.from('profiles').upsert({
            'id': userId,
            'name': '${role.label} (${matchingUser.college})',
            'phone': '+91${matchingUser.phone}',
            'college': matchingUser.college,
            'hostel': hostelStr,
            'room_number': roomNumberStr,
            'role': dbRoleStr,
            'verification_status': statusStr,
            'id_card_path': '',
          });
        }
        
        await _fetchUserProfile();
        await _fetchRequests();
        await _fetchOrders();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = "Could not start session.";
        _setLoading(false);
        return false;
      }
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
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      final isDemo = demoUsers.any((u) => u.phone == cleanPhone);

      if (isDemo) {
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
      final cleanPhone = _currentPhone!.replaceAll(RegExp(r'\D'), '').replaceFirst('91', '');
      final isDemo = demoUsers.any((u) => u.phone == cleanPhone);

      if (isDemo && otp == '123456') {
        final email = 'user_$cleanPhone@hostelhub.com';
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

      // Query real-time food stock overrides from Supabase
      try {
        final stockResponse = await _supabase.from('food_stock').select();
        final stockMap = {
          for (var row in stockResponse as List)
            row['food_name'].toString().toLowerCase(): row['in_stock'] as bool
        };

        for (int i = 0; i < _foodItems.length; i++) {
          final nameKey = _foodItems[i].name.toLowerCase();
          if (stockMap.containsKey(nameKey)) {
            final available = stockMap[nameKey]!;
            final old = _foodItems[i];
            _foodItems[i] = FoodItem(
              id: old.id,
              name: old.name,
              price: old.price,
              isVeg: old.isVeg,
              isAvailable: available,
              category: old.category,
              emoji: old.emoji,
              description: old.description,
              imageUrl: old.imageUrl,
            );
          }
        }
      } catch (stockErr) {
        print('Error fetching food stock overrides: $stockErr');
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

  Future<void> toggleFoodAvailability(String id) async {
    final idx = _foodItems.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final old = _foodItems[idx];
      final newAvailability = !old.isAvailable;
      
      _foodItems[idx] = FoodItem(
        id: old.id,
        name: old.name,
        price: old.price,
        isVeg: old.isVeg,
        isAvailable: newAvailability,
        category: old.category,
        emoji: old.emoji,
        description: old.description,
        imageUrl: old.imageUrl,
      );
      notifyListeners();

      // Persist availability override to Supabase food_stock
      try {
        final quantity = newAvailability ? 1 : 0;
        final existing = await _supabase.from('food_stock').select().eq('food_name', old.name).maybeSingle();
        if (existing != null) {
          await _supabase.from('food_stock').update({
            'quantity': quantity,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);
        } else {
          await _supabase.from('food_stock').insert({
            'food_name': old.name,
            'quantity': quantity,
          });
        }
      } catch (e) {
        print('Error updating food availability in Supabase: $e');
      }
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
        imageUrl: null,
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
        imageUrl: null,
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
        imageUrl: null,
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
        imageUrl: null,
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
        imageUrl: null,
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
        imageUrl: null,
      ),
    ];
  }

  // ── Logout ────────────────────────────────
  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    _requests.clear();
    _orders.clear();
    _announcements.clear();
    _announcementsChannel?.unsubscribe();
    _foodStockChannel?.unsubscribe();
    _requestsChannel?.unsubscribe();
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

  Future<void> fetchAnnouncements() async {
    try {
      final college = _user?.college;
      if (college != null) {
        final response = await _supabase
            .from('announcements')
            .select()
            .eq('college', college)
            .order('created_at', ascending: false);
        _announcements = (response as List)
            .map((e) => AnnouncementModel.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching announcements: $e');
      if (_announcements.isEmpty) {
        _announcements = _getFallbackAnnouncements();
        notifyListeners();
      }
    }
  }

  Future<void> publishAnnouncement(String title, String content) async {
    try {
      final college = _user?.college;
      if (college != null) {
        await _supabase.from('announcements').insert({
          'college': college,
          'title': title,
          'content': content,
        });
        await fetchAnnouncements();
      }
    } catch (e) {
      print('Error publishing announcement: $e');
      final newAnn = AnnouncementModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        college: _user?.college ?? 'RVCE',
        title: title,
        content: content,
        createdAt: DateTime.now(),
      );
      _announcements.insert(0, newAnn);
      notifyListeners();
    }
  }

  void _subscribeToAnnouncements() {
    _announcementsChannel?.unsubscribe();
    final college = _user?.college;
    if (college == null) return;

    _announcementsChannel = _supabase
        .channel('public:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            print('Announcements real-time update: $payload');
            fetchAnnouncements();
          },
        );
    _announcementsChannel?.subscribe();
  }

  List<AnnouncementModel> _getFallbackAnnouncements() {
    return [
      AnnouncementModel(
        id: 'fallback_1',
        college: _user?.college ?? 'RVCE',
        title: '📢 Mess timing changed',
        content: 'Mess timing changed to 7:30 AM – 9:30 AM from Monday',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AnnouncementModel(
        id: 'fallback_2',
        college: _user?.college ?? 'RVCE',
        title: '🛠️ Scheduled maintenance',
        content: 'Scheduled maintenance on Block C lifts this Saturday',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AnnouncementModel(
        id: 'fallback_3',
        college: _user?.college ?? 'RVCE',
        title: '🎉 Night Canteen menu updated',
        content: 'Night Canteen menu updated! Try new Momos & Rolls',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void _subscribeToFoodStock() {
    _foodStockChannel?.unsubscribe();
    _foodStockChannel = _supabase
        .channel('public:food_stock')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'food_stock',
          callback: (payload) {
            print('Food stock real-time change: $payload');
            fetchFoodItems();
          },
        );
    _foodStockChannel?.subscribe();
  }

  void _subscribeToRequests() {
    _requestsChannel?.unsubscribe();
    _requestsChannel = _supabase
        .channel('public:requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_requests',
          callback: (payload) {
            print('Service requests real-time change: $payload');
            _fetchRequests();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'maintenance_requests',
          callback: (payload) {
            print('Maintenance requests real-time change: $payload');
            _fetchRequests();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lost_requests',
          callback: (payload) {
            print('Lost requests real-time change: $payload');
            _fetchRequests();
          },
        );
    _requestsChannel?.subscribe();
  }
}
