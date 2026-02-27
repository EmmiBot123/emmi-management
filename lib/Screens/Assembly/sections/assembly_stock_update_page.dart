import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/Marketing/ProductRequest.dart';
import '../../../Model/productDetails/ProductOption.dart';
import '../../../Providers/Product/ProductProvider.dart';
import '../../../Model/productDetails/deliveryHistory.dart';

class AssemblyStockUpdatePage extends StatefulWidget {
  final String schoolId;
  final List<ProductRequest> visitProducts;

  const AssemblyStockUpdatePage({
    super.key,
    required this.visitProducts,
    required this.schoolId,
  });

  @override
  State<AssemblyStockUpdatePage> createState() =>
      _AssemblyStockUpdatePageState();
}

class _AssemblyStockUpdatePageState extends State<AssemblyStockUpdatePage> {
  bool confirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAvailableProducts();
    });
  }

  /// Normalize visit product name
  String normalizeVisitName(String name) {
    return name.split('(').first.trim();
  }

  /// Check if already delivered to school
  bool alreadyDelivered(ProductOption product, String schoolId) {
    return product.deliveryHistories.any(
      (h) => h.schoolId == schoolId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final schoolId = widget.schoolId;

    final alreadyDone = provider.availableProducts.any(
      (p) => alreadyDelivered(p, schoolId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assembly Stock Update"),
      ),
      body: provider.availableProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (alreadyDone)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Stock already deducted for this school",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: widget.visitProducts
                        .map(
                          (visitProduct) => _buildProductSection(
                            provider,
                            visitProduct,
                          ),
                        )
                        .toList(),
                  ),
                ),

                /// CONFIRM BUTTON
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: confirming
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.inventory),
                    label: Text(
                      confirming
                          ? "Updating Stock..."
                          : "Confirm & Deduct Stock",
                    ),
                    onPressed: confirming || alreadyDone
                        ? null
                        : () async {
                            setState(() => confirming = true);

                            final now = DateTime.now().toIso8601String();

                            final productsToUpdate = List<ProductOption>.from(
                              provider.availableProducts,
                            );

                            for (final product in productsToUpdate) {
                              if (alreadyDelivered(product, schoolId)) {
                                continue;
                              }

                              final visitProduct =
                                  widget.visitProducts.firstWhere(
                                (v) =>
                                    normalizeVisitName(v.name) == product.name,
                              );

                              final qty = visitProduct.quantity;

                              /// 🔹 1. Reduce component stock IMMUTABLY
                              final updatedComponents =
                                  product.components.map((component) {
                                final used = component.qtyRequired * qty;

                                return ProductComponent(
                                  componentId: component.componentId,
                                  componentName: component.componentName,
                                  qtyRequired: component.qtyRequired,
                                  availableStock:
                                      (component.availableStock - used)
                                          .clamp(0, component.availableStock),
                                );
                              }).toList();

                              /// 🔹 2. Update delivery history
                              final updatedHistory = List<DeliveryHistory>.from(
                                product.deliveryHistories,
                              )..add(
                                  DeliveryHistory(
                                    schoolId: schoolId,
                                    date: now,
                                    productQty: qty.toString(),
                                  ),
                                );

                              /// 🔹 3. Create updated product
                              final updatedProduct = ProductOption(
                                id: product.id,
                                name: product.name,
                                types: product.types,
                                components: updatedComponents,
                                deliveryHistories: updatedHistory,
                              );

                              /// 🔹 4. Save
                              await provider.addProduct(updatedProduct);
                            }

                            setState(() => confirming = false);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Stock updated & delivery saved",
                                ),
                              ),
                            );

                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// PRODUCT SECTION
  Widget _buildProductSection(
    ProductProvider provider,
    ProductRequest visitProduct,
  ) {
    final product = provider.availableProducts.firstWhere(
      (p) =>
          p.name ==
          normalizeVisitName(
            visitProduct.name,
          ),
      orElse: () => const ProductOption(),
    );

    if (product.name.isEmpty) {
      return Card(
        color: Colors.red.shade50,
        child: ListTile(
          title: Text(visitProduct.name),
          subtitle: const Text("Product not found in stock list"),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${product.name} × ${visitProduct.quantity}",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...product.components.map(
          (component) {
            final before = component.availableStock;
            final used = component.qtyRequired * visitProduct.quantity;

            // UI DISPLAY ONLY - do not mutate component here
            final after = (before - used).clamp(0, before);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.componentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _info("Required / Unit",
                            component.qtyRequired.toString()),
                        _info("Total Used", used.toString(), color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _info("Before", before.toString()),
                        _info(
                          "After",
                          after.toString(),
                          color: after == 0 ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(),
        // Removed side-effect Builder
      ],
    );
  }

  Widget _info(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
