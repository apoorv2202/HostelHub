// ─────────────────────────────────────────────
//  NightCanteenScreen — Food ordering UI
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../services/squidex_service.dart';
import 'cart_screen.dart';

class NightCanteenScreen extends StatefulWidget {
  const NightCanteenScreen({super.key});

  @override
  State<NightCanteenScreen> createState() => _NightCanteenScreenState();
}

class _NightCanteenScreenState extends State<NightCanteenScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _categories = [
    'All', 'Snacks', 'Sandwich', 'Burger', 'Rolls', 'Egg', 'Beverages'
  ];

  bool _isLoading = true;
  List<FoodItem> _foodItems = [];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _categories.length, vsync: this);
    _fetchFoodItems();
  }

  Future<void> _fetchFoodItems() async {
    try {
      final items = await SquidexService().getFoodItems();
      setState(() {
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching food items: \$e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FoodItem> _filteredItems(String category) {
    return _foodItems.where((item) {
      final matchesCategory =
          category == 'All' || item.category == category;
      final matchesSearch = item.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Night Canteen 🍜'),
        backgroundColor: Colors.white,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '\${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // ── Search bar ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search food...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textMedium),
                    filled: true,
                    fillColor: AppTheme.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // ── Category tabs ─────────────────────────
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMedium,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs:
                    _categories.map((c) => Tab(text: c)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          // ── Canteen timing banner ─────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppTheme.secondary),
                const SizedBox(width: 8),
                const Text(
                  'Open 8:00 PM – 2:00 AM  ·  Delivery: ~15 min',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Items list ─────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final items = _filteredItems(cat);
                if (items.isEmpty) {
                  return const EmptyState(
                    emoji: '🍽️',
                    title: 'Nothing here',
                    subtitle: 'No items in this category right now',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) =>
                      _FoodItemCard(item: items[i]),
                );
              }).toList(),
            ),
          ),
        ],
      ),

      // ── Floating cart bar ─────────────────────
      bottomNavigationBar: cart.itemCount > 0
          ? Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16,
                  MediaQuery.of(context).padding.bottom + 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${cart.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Food Item Card ─────────────────────────
class _FoodItemCard extends StatelessWidget {
  final FoodItem item;

  const _FoodItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);
    final inCart = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inCart
              ? AppTheme.primary.withOpacity(0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // ── Emoji thumbnail ───────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Details ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: item.isVeg),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (!item.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (inCart)
                      QuantityStepper(
                        quantity: qty,
                        onAdd: () =>
                            context.read<CartProvider>().addItem(item),
                        onRemove: () =>
                            context.read<CartProvider>().removeItem(item),
                      )
                    else
                      GestureDetector(
                        onTap: () =>
                            context.read<CartProvider>().addItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
