// ─────────────────────────────────────────────
//  CartProvider — Night Canteen cart state
// ─────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => subtotal > 0 ? 10.0 : 0.0;
  double get taxes => subtotal * 0.05; // 5% GST
  double get grandTotal => subtotal + deliveryFee + taxes;

  // ── Check if item is in cart ───────────────
  bool hasItem(String foodItemId) =>
      _items.any((i) => i.foodItem.id == foodItemId);

  int quantityOf(String foodItemId) {
    final match = _items.where((i) => i.foodItem.id == foodItemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  // ── Add item ──────────────────────────────
  void addItem(FoodItem item) {
    final index = _items.indexWhere((i) => i.foodItem.id == item.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(foodItem: item));
    }
    notifyListeners();
  }

  // ── Remove one quantity ───────────────────
  void removeItem(FoodItem item) {
    final index = _items.indexWhere((i) => i.foodItem.id == item.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
    }
    notifyListeners();
  }

  // ── Remove entirely ───────────────────────
  void removeAll(String foodItemId) {
    _items.removeWhere((i) => i.foodItem.id == foodItemId);
    notifyListeners();
  }

  // ── Clear cart ────────────────────────────
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
