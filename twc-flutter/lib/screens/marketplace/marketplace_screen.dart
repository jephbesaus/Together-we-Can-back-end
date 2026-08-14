import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../core/models/product.dart';
import '../../widgets/app_loader.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _api = Get.find<ApiService>();

  List<Product> _products = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _selectedSort = 'newest';
  bool _isLoading = true;
  bool _hasMore = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadProducts(page: _currentPage + 1);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCategories(),
      _loadProducts(page: 1),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _api.get('/marketplace/products/categories');
      if (response['success']) {
        setState(() {
          // Le backend renvoie une liste de chaînes (pluck), pas d'objets {name: ...}
          _categories = List<String>.from(response['data']['categories'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadProducts({int page = 1, String? category, String? sort}) async {
    try {
      final params = {
        'page': page,
        'limit': 20,
        if (category != null) 'category': category,
        if (sort != null) 'sort': sort,
      };

      final response = await _api.get('/marketplace/products', params: params);

      if (response['success']) {
        final data = response['data'];
        final newProducts = (data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList();

        setState(() {
          if (page == 1) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _currentPage = page;
          _hasMore = data['has_more'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '🛒 Marketplace',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Get.toNamed('/orders'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_categories.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryChip('Tous', _selectedCategory == null);
                    }
                    final category = _categories[index - 1];
                    return _buildCategoryChip(category, _selectedCategory == category);
                  },
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Trier:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedSort,
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Plus récent')),
                      DropdownMenuItem(value: 'price_low', child: Text('Prix croissant')),
                      DropdownMenuItem(value: 'price_high', child: Text('Prix décroissant')),
                      DropdownMenuItem(value: 'popular', child: Text('Plus populaires')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSort = value);
                        _loadProducts(page: 1, sort: value);
                      }
                    },
                  ),
                  const Spacer(),
                  Text('${_products.length} produits'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? const AppLoadingView(message: 'Chargement des produits...')
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun produit trouvé',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _products.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildProductCard(_products[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-product'),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = selected ? null : label;
            _loadProducts(page: 1, category: _selectedCategory);
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () {
        Get.toNamed('/product-detail', arguments: product.id);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.mainImage != null
                    ? CachedNetworkImage(
                        imageUrl: MediaService.resolveUrl(product.mainImage)!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviewsCount})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
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
