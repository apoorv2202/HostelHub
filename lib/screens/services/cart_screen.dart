// lib/screens/services/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;
  bool _orderPlaced = false;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _isOrdering = true);
    await Future.delayed(const Duration(seconds: 2));

    // Convert cart items to order items
    final orderItems = cart.items
        .map((ci) => OrderItem(
              name: ci.foodItem.name,
              quantity: ci.quantity,
              price: ci.foodItem.price,
            ))
        .toList();

    if (mounted) {
      await context.read<AppProvider>().addOrder(orderItems, cart.grandTotal);
      cart.clear();
      setState(() {
        _isOrdering = false;
        _orderPlaced = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Your Cart 🛒'),
          backgroundColor: Colors.transparent,
          actions: [
            if (cart.items.isNotEmpty && !_orderPlaced)
              TextButton(
                onPressed: () => _showClearDialog(context),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: AppTheme.statusRejected,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: _orderPlaced
            ? _buildSuccessView()
            : cart.items.isEmpty
                ? const EmptyState(
                    emoji: '🛒',
                    title: 'Your cart is empty',
                    subtitle: 'Add items from the night canteen to place an order',
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // ── Cart items ─────────────────────────────
                            ...cart.items.map((ci) => _CartItemTile(
                                  cartItem: ci,
                                )),

                            const SizedBox(height: 16),

                            // ── Delivery address ──────────────────────
                            _buildAddressCard(),

                            const SizedBox(height: 16),

                            // ── Bill summary ──────────────────────────
                            _buildBillSummary(cart),

                            const SizedBox(height: 16),

                            // ── Terms note ────────────────────────────
                            GlassCard(
                              padding: const EdgeInsets.all(12),
                              radius: AppTheme.radiusSm,
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 14, color: AppTheme.primaryOrange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Delivery to your hostel door. Estimated: 15–20 minutes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Place order button ────────────────────
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            16, 16, 16,
                            MediaQuery.of(context).padding.bottom + 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withOpacity(0.9),
                          border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total to pay',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                                Text(
                                  '₹${cart.grandTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GradientButton(
                              label: 'Place Order  ·  Pay ₹${cart.grandTotal.toStringAsFixed(0)}',
                              onPressed: _placeOrder,
                              loading: _isOrdering,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.statusCompleted.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.statusCompleted.withOpacity(0.35)),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.statusCompleted, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to',
                  style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
                Text(
                  'Your Hostel Room',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummary(CartProvider cart) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 14),
          _BillRow('Item Total', '₹${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _BillRow('Delivery Fee', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _BillRow('GST (5%)', '₹${cart.taxes.toStringAsFixed(0)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 0),
          ),
          _BillRow(
            'Grand Total',
            '₹${cart.grandTotal.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            const Text(
              'Order Placed!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your food is being prepared.\nEstimated delivery: 15–20 minutes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Track Order',
              onPressed: () => Navigator.pop(context),
              icon: Icons.track_changes_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.statusRejected)),
          ),
        ],
      ),
    );
  }
}

// ── Cart item row ─────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const _CartItemTile({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: AppTheme.radiusSm,
      child: Row(
        children: [
          Text(cartItem.foodItem.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.foodItem.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '₹${cartItem.foodItem.price.toStringAsFixed(0)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              QuantityStepper(
                quantity: cartItem.quantity,
                onAdd: () =>
                    context.read<CartProvider>().addItem(cartItem.foodItem),
                onRemove: () =>
                    context.read<CartProvider>().removeItem(cartItem.foodItem),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${cartItem.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bill Row helper ───────────────────────
class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _BillRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppTheme.textWhite : AppTheme.textGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppTheme.primaryOrange : AppTheme.textWhite,
          ),
        ),
      ],
    );
  }
}
