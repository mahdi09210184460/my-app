import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../models/shop_item_model.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../core/theme/app_colors.dart';
import 'product_details_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<ShopItemModel> _items = [];
  List<String> _categories = ['همه'];
  String _selectedCategory = 'همه';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cats = await ShopService.getCategories();
      final items = await ShopService.getActiveItems(category: _selectedCategory);
      setState(() {
        _categories = cats;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه سکه‌چی'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: _isLoading
                ? const AppLoading(message: 'در حال بارگذاری محصولات...')
                : _errorMessage != null
                    ? AppErrorState(message: _errorMessage!, onRetry: _loadData)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _items.isEmpty
                            ? const AppEmptyState(title: 'محصولی یافت نشد', message: 'در این دسته‌بندی فعلاً محصولی موجود نیست.')
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (context, index) => _ProductCard(item: _items[index]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.primaryPurple.withValues(alpha: 0.05),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedCategory = cat);
                  _loadData();
                }
              },
              selectedColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ShopItemModel item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isCoinProduct = item.coinPrice > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(item: item))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryPurple.withValues(alpha: 0.05),
                    child: item.image != null
                        ? Image.network(item.image!, fit: BoxFit.cover)
                        : const Icon(Icons.shopping_bag_outlined, size: 60, color: AppColors.divider),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isCoinProduct ? Icons.monetization_on : Icons.payments_outlined,
                        size: 16,
                        color: isCoinProduct ? AppColors.coinGoldDark : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCoinProduct ? '${item.coinPrice} سکه' : '${item.price} تومان',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isCoinProduct ? AppColors.primaryPurple : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
