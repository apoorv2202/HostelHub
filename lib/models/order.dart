enum OrderStatus { pending, accepted, preparing, ready, completed }

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
    }
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

class FoodOrder {
  final String id;
  final String studentName;
  final String roomNumber;
  final List<OrderItem> items;
  final DateTime createdAt;
  OrderStatus status;
  final String? specialNote;

  FoodOrder({
    required this.id,
    required this.studentName,
    required this.roomNumber,
    required this.items,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.specialNote,
  });

  double get totalPrice => items.fold(0, (sum, item) => sum + item.total);
}

class MockOrderData {
  static List<FoodOrder> orders = [
    FoodOrder(
      id: 'ORD001',
      studentName: 'Arjun Sharma',
      roomNumber: 'B-204',
      createdAt: DateTime.now().subtract(Duration(minutes: 5)),
      specialNote: 'Extra spicy please',
      items: [
        OrderItem(name: 'Paneer Butter Masala', quantity: 1, price: 120),
        OrderItem(name: 'Butter Naan', quantity: 3, price: 30),
        OrderItem(name: 'Lassi', quantity: 1, price: 40),
      ],
    ),
    FoodOrder(
      id: 'ORD002',
      studentName: 'Priya Singh',
      roomNumber: 'A-101',
      createdAt: DateTime.now().subtract(Duration(minutes: 18)),
      status: OrderStatus.accepted,
      items: [
        OrderItem(name: 'Veg Biryani', quantity: 1, price: 150),
        OrderItem(name: 'Raita', quantity: 1, price: 30),
      ],
    ),
    FoodOrder(
      id: 'ORD003',
      studentName: 'Rahul Nair',
      roomNumber: 'C-312',
      createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      status: OrderStatus.preparing,
      items: [
        OrderItem(name: 'Masala Dosa', quantity: 2, price: 80),
        OrderItem(name: 'Filter Coffee', quantity: 2, price: 35),
        OrderItem(name: 'Sambar', quantity: 1, price: 20),
      ],
    ),
    FoodOrder(
      id: 'ORD004',
      studentName: 'Sneha Reddy',
      roomNumber: 'B-105',
      createdAt: DateTime.now().subtract(Duration(minutes: 45)),
      status: OrderStatus.ready,
      items: [
        OrderItem(name: 'Chole Bhature', quantity: 1, price: 100),
        OrderItem(name: 'Cold Coffee', quantity: 1, price: 60),
      ],
    ),
    FoodOrder(
      id: 'ORD005',
      studentName: 'Vikram Mehta',
      roomNumber: 'D-208',
      createdAt: DateTime.now().subtract(Duration(hours: 1, minutes: 15)),
      status: OrderStatus.completed,
      specialNote: 'No onion no garlic',
      items: [
        OrderItem(name: 'Dal Tadka', quantity: 1, price: 90),
        OrderItem(name: 'Steamed Rice', quantity: 1, price: 60),
        OrderItem(name: 'Papad', quantity: 2, price: 15),
      ],
    ),
    FoodOrder(
      id: 'ORD006',
      studentName: 'Ananya Iyer',
      roomNumber: 'A-215',
      createdAt: DateTime.now().subtract(Duration(minutes: 2)),
      items: [
        OrderItem(name: 'Maggi', quantity: 2, price: 50),
        OrderItem(name: 'Bread Omelette', quantity: 1, price: 70),
        OrderItem(name: 'Chai', quantity: 2, price: 25),
      ],
    ),
  ];
}
