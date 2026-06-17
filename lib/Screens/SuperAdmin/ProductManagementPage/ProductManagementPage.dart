import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Providers/Product/ProductProvider.dart';
import 'Product_detailed_page.dart';
import 'create_product_page.dart';
import '../../../../Model/productDetails/ProductOption.dart';

// ─── Color Palette ───
class _Palette {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF38BDF8);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const success = Color(0xFF10B981);
}

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    loadProducts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    await context.read<ProductProvider>().fetchAvailableProducts();
    if (mounted) {
      setState(() => loading = false);
      _fadeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final List<ProductOption> products = provider.availableProducts;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _Palette.textPrimary),
        title: const Text(
          "Product Management",
          style: TextStyle(
            color: _Palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductPage()),
          );
        },
        backgroundColor: _Palette.accent,
        icon: const Icon(Icons.add, color: _Palette.bg),
        label: const Text(
          "Add Product",
          style: TextStyle(color: _Palette.bg, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Content
          loading
              ? const Center(
                  child: CircularProgressIndicator(color: _Palette.accent),
                )
              : RefreshIndicator(
                  color: _Palette.accent,
                  backgroundColor: _Palette.surface,
                  onRefresh: loadProducts,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: products.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.7,
                                child: const Center(
                                  child: Text(
                                    "No products found",
                                    style: TextStyle(
                                      color: _Palette.textSecondary,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 3 : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWide ? 1.5 : 2.5,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(products[index], index);
                            },
                          ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductOption p, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(product: p),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _Palette.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.precision_manufacturing,
                            color: _Palette.accent, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _Palette.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${p.components.length} Components",
                          style: const TextStyle(
                            color: _Palette.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: _Palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.types.take(3).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: _Palette.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
