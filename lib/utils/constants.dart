// ─────────────────────────────────────────────
//  Constants & Mock Data — Hostel Hub
// ─────────────────────────────────────────────
import '../models/food_item.dart';
import '../models/request_model.dart';
import '../models/order_model.dart';

// ── College & Hostel data ──────────────────
const Map<String, List<String>> collegeHostels = {
  'IIT Delhi': [
    'Aravali Hostel',
    'Girnar Hostel',
    'Karakoram Hostel',
    'Kumaon Hostel',
    'Nilgiri Hostel',
    'Vindhyachal Hostel',
    'Zanskar Hostel',
  ],
  'IIT Bombay': [
    'H1 - Hostel 1',
    'H3 - Hostel 3',
    'H5 - Hostel 5',
    'H10 - Hostel 10',
    'H13 - Hostel 13',
    'H15 - Hostel 15',
  ],
  'NIT Trichy': [
    'Cauvery Hostel',
    'Ganga Hostel',
    'Godavari Hostel',
    'Narmada Hostel',
    'Saraswathi Hostel',
    'Tapti Hostel',
  ],
  'VIT Vellore': [
    'A Block',
    'C Block',
    'G Block',
    'MB Block',
    'MG Block',
    'SJT Block',
  ],
  'BITS Pilani': [
    'Bhagirath Bhawan',
    'Buddha Bhawan',
    'CV Raman Bhawan',
    'Gandhi Bhawan',
    'Meera Bhawan',
    'Ram Bhawan',
  ],
  'Delhi University': [
    'Gwyer Hall',
    'Jubilee Hall',
    'Mansarovar Hostel',
    'Mukherji Hostel',
    'Rudra North Hall',
  ],
};

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
