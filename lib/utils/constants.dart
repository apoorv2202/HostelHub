// ─────────────────────────────────────────────
//  Constants & Mock Data — Hostel Hub
// ─────────────────────────────────────────────
import '../models/food_item.dart';
import '../models/request_model.dart';
import '../models/order_model.dart';

// ── College & Hostel data ──────────────────
const Map<String, List<String>> collegeHostels = {
  'RVCE': [
    'Cauvery Hostel',
    'Krishna Hostel',
    'Chamundi Hostel',
    'MV Hostel',
  ],
  'BMS': [
    'Nethravathi Hostel',
    'Suvarna Hostel',
    'LH Hostel',
  ],
  'PES': [
    'Vindhya Hostel',
    'Aravali Hostel',
    'LH Hostel',
  ],
  'Ramaiah': [
    'Ganga Hostel',
    'Yamuna Hostel',
    'LH Hostel',
  ],
};

class DemoUser {
  final String phone;
  final String role; // 'student', 'warden', 'cleaner', 'canteen', 'maintenance'
  final String college;
  final String hostel;
  final String id; // Standard ID
  final String room;

  const DemoUser({
    required this.phone,
    required this.role,
    required this.college,
    required this.hostel,
    required this.id,
    required this.room,
  });
}

const List<DemoUser> demoUsers = [
  // ── RVCE ──
  DemoUser(phone: '9876500001', role: 'warden', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-WARDEN-01', room: 'W-101'),
  DemoUser(phone: '9876500002', role: 'cleaner', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-CLEANER-01', room: 'C-101'),
  DemoUser(phone: '9876500003', role: 'maintenance', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-MAINT-01', room: 'M-101'),
  DemoUser(phone: '9876500004', role: 'student', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-ST-CAUVERY-01', room: 'A-101'),
  DemoUser(phone: '9876500005', role: 'student', college: 'RVCE', hostel: 'Krishna Hostel', id: 'RVCE-ST-KRISHNA-01', room: 'B-101'),
  DemoUser(phone: '9876500006', role: 'student', college: 'RVCE', hostel: 'Chamundi Hostel', id: 'RVCE-ST-CHAMUNDI-01', room: 'C-101'),
  DemoUser(phone: '9876500007', role: 'canteen', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-CANTEEN-01', room: 'K-101'),
  // Flexible RVCE Students (Can manually assign hostels, rooms, and IDs)
  DemoUser(phone: '9876500011', role: 'student', college: 'RVCE', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876500012', role: 'student', college: 'RVCE', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876500013', role: 'student', college: 'RVCE', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876500014', role: 'student', college: 'RVCE', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876500015', role: 'student', college: 'RVCE', hostel: '', id: '', room: ''),

  // ── BMS ──
  DemoUser(phone: '9876510001', role: 'warden', college: 'BMS', hostel: 'Nethravathi Hostel', id: 'BMS-WARDEN-01', room: 'W-101'),
  DemoUser(phone: '9876510002', role: 'cleaner', college: 'BMS', hostel: 'Nethravathi Hostel', id: 'BMS-CLEANER-01', room: 'C-101'),
  DemoUser(phone: '9876510003', role: 'maintenance', college: 'BMS', hostel: 'Nethravathi Hostel', id: 'BMS-MAINT-01', room: 'M-101'),
  DemoUser(phone: '9876510004', role: 'student', college: 'BMS', hostel: 'Nethravathi Hostel', id: 'BMS-ST-NETHRA-01', room: 'A-101'),
  DemoUser(phone: '9876510005', role: 'student', college: 'BMS', hostel: 'Suvarna Hostel', id: 'BMS-ST-SUVARNA-01', room: 'B-101'),
  DemoUser(phone: '9876510006', role: 'student', college: 'BMS', hostel: 'LH Hostel', id: 'BMS-ST-LH-01', room: 'C-101'),
  DemoUser(phone: '9876510007', role: 'canteen', college: 'BMS', hostel: 'Nethravathi Hostel', id: 'BMS-CANTEEN-01', room: 'K-101'),
  // Flexible BMS Students
  DemoUser(phone: '9876510011', role: 'student', college: 'BMS', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876510012', role: 'student', college: 'BMS', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876510013', role: 'student', college: 'BMS', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876510014', role: 'student', college: 'BMS', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876510015', role: 'student', college: 'BMS', hostel: '', id: '', room: ''),

  // ── PES ──
  DemoUser(phone: '9876520001', role: 'warden', college: 'PES', hostel: 'Vindhya Hostel', id: 'PES-WARDEN-01', room: 'W-101'),
  DemoUser(phone: '9876520002', role: 'cleaner', college: 'PES', hostel: 'Vindhya Hostel', id: 'PES-CLEANER-01', room: 'C-101'),
  DemoUser(phone: '9876520003', role: 'maintenance', college: 'PES', hostel: 'Vindhya Hostel', id: 'PES-MAINT-01', room: 'M-101'),
  DemoUser(phone: '9876520004', role: 'student', college: 'PES', hostel: 'Vindhya Hostel', id: 'PES-ST-VINDHYA-01', room: 'A-101'),
  DemoUser(phone: '9876520005', role: 'student', college: 'PES', hostel: 'Aravali Hostel', id: 'PES-ST-ARAVALI-01', room: 'B-101'),
  DemoUser(phone: '9876520006', role: 'student', college: 'PES', hostel: 'LH Hostel', id: 'PES-ST-LH-01', room: 'C-101'),
  DemoUser(phone: '9876520007', role: 'canteen', college: 'PES', hostel: 'Vindhya Hostel', id: 'PES-CANTEEN-01', room: 'K-101'),
  // Flexible PES Students
  DemoUser(phone: '9876520011', role: 'student', college: 'PES', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876520012', role: 'student', college: 'PES', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876520013', role: 'student', college: 'PES', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876520014', role: 'student', college: 'PES', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876520015', role: 'student', college: 'PES', hostel: '', id: '', room: ''),

  // ── Ramaiah ──
  DemoUser(phone: '9876530001', role: 'warden', college: 'Ramaiah', hostel: 'Ganga Hostel', id: 'RAMAIAH-WARDEN-01', room: 'W-101'),
  DemoUser(phone: '9876530002', role: 'cleaner', college: 'Ramaiah', hostel: 'Ganga Hostel', id: 'RAMAIAH-CLEANER-01', room: 'C-101'),
  DemoUser(phone: '9876530003', role: 'maintenance', college: 'Ramaiah', hostel: 'Ganga Hostel', id: 'RAMAIAH-MAINT-01', room: 'M-101'),
  DemoUser(phone: '9876530004', role: 'student', college: 'Ramaiah', hostel: 'Ganga Hostel', id: 'RAMAIAH-ST-GANGA-01', room: 'A-101'),
  DemoUser(phone: '9876530005', role: 'student', college: 'Ramaiah', hostel: 'Yamuna Hostel', id: 'RAMAIAH-ST-YAMUNA-01', room: 'B-101'),
  DemoUser(phone: '9876530006', role: 'student', college: 'Ramaiah', hostel: 'LH Hostel', id: 'RAMAIAH-ST-LH-01', room: 'C-101'),
  DemoUser(phone: '9876530007', role: 'canteen', college: 'Ramaiah', hostel: 'Ganga Hostel', id: 'RAMAIAH-CANTEEN-01', room: 'K-101'),
  // Flexible Ramaiah Students
  DemoUser(phone: '9876530011', role: 'student', college: 'Ramaiah', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876530012', role: 'student', college: 'Ramaiah', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876530013', role: 'student', college: 'Ramaiah', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876530014', role: 'student', college: 'Ramaiah', hostel: '', id: '', room: ''),
  DemoUser(phone: '9876530015', role: 'student', college: 'Ramaiah', hostel: '', id: '', room: ''),

  // Compatibility test users
  DemoUser(phone: '9876543210', role: 'student', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-ST-TEST', room: 'T-101'),
  DemoUser(phone: '9876543211', role: 'warden', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-WARDEN-TEST', room: 'W-101'),
  DemoUser(phone: '9876543212', role: 'canteen', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-CANTEEN-TEST', room: 'C-101'),
  DemoUser(phone: '9876543213', role: 'cleaner', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-CLEANER-TEST', room: 'CL-101'),
  DemoUser(phone: '9876543214', role: 'maintenance', college: 'RVCE', hostel: 'Cauvery Hostel', id: 'RVCE-MAINT-TEST', room: 'MN-101'),
];

// ── Mock Night Canteen food items ──────────
final List<FoodItem> mockFoodItems = [
  FoodItem(
    id: '1',
    name: 'Maggi Noodles',
    price: 30,
    isVeg: true,
    isAvailable: true,
    category: 'Snacks',
    emoji: '🍜',
    description: 'Classic Masala Maggi with veggies',
    imageUrl: null,
  ),
  FoodItem(
    id: '2',
    name: 'Chicken Sandwich',
    price: 60,
    isVeg: false,
    isAvailable: true,
    category: 'Sandwich',
    emoji: '🥪',
    description: 'Grilled chicken with lettuce & mayo',
    imageUrl: null,
  ),
  FoodItem(
    id: '3',
    name: 'Masala Chai',
    price: 15,
    isVeg: true,
    isAvailable: true,
    category: 'Beverages',
    emoji: '☕',
    description: 'Freshly brewed spiced tea',
    imageUrl: null,
  ),
  FoodItem(
    id: '4',
    name: 'Egg Bhurji',
    price: 50,
    isVeg: false,
    isAvailable: true,
    category: 'Egg',
    emoji: '🍳',
    description: 'Spicy scrambled eggs with onions',
    imageUrl: null,
  ),
  FoodItem(
    id: '5',
    name: 'Veg Burger',
    price: 55,
    isVeg: true,
    isAvailable: false,
    category: 'Burger',
    emoji: '🍔',
    description: 'Aloo tikki burger with cheese',
    imageUrl: null,
  ),
  FoodItem(
    id: '6',
    name: 'Cold Coffee',
    price: 45,
    isVeg: true,
    isAvailable: true,
    category: 'Beverages',
    emoji: '🥤',
    description: 'Thick chilled coffee with cream',
    imageUrl: null,
  ),
  FoodItem(
    id: '7',
    name: 'Paneer Roll',
    price: 70,
    isVeg: true,
    isAvailable: true,
    category: 'Rolls',
    emoji: '🌯',
    description: 'Spicy paneer tikka wrapped in paratha',
    imageUrl: null,
  ),
  FoodItem(
    id: '8',
    name: 'Chicken Momos',
    price: 80,
    isVeg: false,
    isAvailable: true,
    category: 'Snacks',
    emoji: '🥟',
    description: '8 piece steamed momos with chutney',
    imageUrl: null,
  ),
  FoodItem(
    id: '9',
    name: 'French Fries',
    price: 40,
    isVeg: true,
    isAvailable: false,
    category: 'Snacks',
    emoji: '🍟',
    description: 'Crispy salted fries with ketchup',
    imageUrl: null,
  ),
  FoodItem(
    id: '10',
    name: 'Boiled Eggs (2)',
    price: 20,
    isVeg: false,
    isAvailable: true,
    category: 'Egg',
    emoji: '🥚',
    description: 'Two hard-boiled eggs with salt',
    imageUrl: null,
  ),
];

// ── Mock Requests ──────────────────────────
final List<RequestModel> mockRequests = [
  RequestModel(
    id: 'REQ001',
    type: RequestType.cleaning,
    title: 'Deep Cleaning',
    description: 'Full room deep cleaning with mopping',
    status: RequestStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    completedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  RequestModel(
    id: 'REQ002',
    type: RequestType.maintenance,
    title: 'Fan Repair',
    description: 'Ceiling fan is making a loud noise',
    status: RequestStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    completedAt: null,
    category: 'Electrician',
  ),
  RequestModel(
    id: 'REQ003',
    type: RequestType.cleaning,
    title: 'Normal Cleaning',
    description: 'Regular sweep and dusting',
    status: RequestStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    completedAt: null,
  ),
  RequestModel(
    id: 'REQ004',
    type: RequestType.maintenance,
    title: 'Chair Broken',
    description: 'Study chair leg is broken',
    status: RequestStatus.completed,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    completedAt: DateTime.now().subtract(const Duration(days: 6)),
    category: 'Furniture',
  ),
];

// ── Mock Orders ────────────────────────────
final List<OrderModel> mockOrders = [
  OrderModel(
    id: 'ORD001',
    items: [
      OrderItem(name: 'Maggi Noodles', quantity: 2, price: 30),
      OrderItem(name: 'Masala Chai', quantity: 1, price: 15),
    ],
    status: OrderStatus.delivered,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    total: 75,
  ),
  OrderModel(
    id: 'ORD002',
    items: [
      OrderItem(name: 'Chicken Momos', quantity: 1, price: 80),
      OrderItem(name: 'Cold Coffee', quantity: 2, price: 45),
    ],
    status: OrderStatus.preparing,
    createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    total: 170,
  ),
  OrderModel(
    id: 'ORD003',
    items: [
      OrderItem(name: 'Paneer Roll', quantity: 1, price: 70),
      OrderItem(name: 'Egg Bhurji', quantity: 1, price: 50),
    ],
    status: OrderStatus.delivered,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    total: 120,
  ),
];
