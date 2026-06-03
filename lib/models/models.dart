// ─────────────────────────────────────────────
//  food_item.dart
// ─────────────────────────────────────────────
class FoodItem {
  final String id;
  final String name;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final String category;
  final String emoji;
  final String description;
  final String? imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    required this.category,
    required this.emoji,
    required this.description,
    this.imageUrl,
  });
}

// ─────────────────────────────────────────────
//  request_model.dart
// ─────────────────────────────────────────────
enum RequestType { cleaning, maintenance, lostItem }


enum RequestStatus { pending, inProgress, completed, rejected }

class RequestModel {
  final String id;
  final RequestType type;
  final String title;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? category; // for maintenance: Electrician / Furniture
  final String? imagePath;

  RequestModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.category,
    this.imagePath,
  });
}

// ─────────────────────────────────────────────
//  order_model.dart
// ─────────────────────────────────────────────
enum OrderStatus { placed, preparing, outForDelivery, delivered, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class OrderModel {
  final String id;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final double total;

  OrderModel({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.total,
  });
}

// ─────────────────────────────────────────────
//  cart_item.dart (used by CartProvider)
// ─────────────────────────────────────────────
class CartItem {
  final FoodItem foodItem;
  int quantity;

  CartItem({required this.foodItem, this.quantity = 1});

  double get subtotal => foodItem.price * quantity;
}

// ---------------------------------------------
//  college_hostel_models.dart
// ---------------------------------------------
class CollegeModel {
  final String id;
  final String name;

  CollegeModel({required this.id, required this.name});
}

class HostelModel {
  final String id;
  final String name;
  final String? collegeId;

  HostelModel({required this.id, required this.name, this.collegeId});
}

class AnnouncementModel {
  final String id;
  final String college;
  final String title;
  final String content;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.college,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'].toString(),
      college: json['college'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
