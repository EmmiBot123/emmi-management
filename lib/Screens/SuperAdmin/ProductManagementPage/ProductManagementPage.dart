import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Providers/Product/ProductProvider.dart';
import 'Product_detailed_page.dart';
import 'create_product_page.dart';
import '../../../../Model/productDetails/ProductOption.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    loading = true;
    setState(() {});
    await context.read<ProductProvider>().fetchAvailableProducts();
    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final List<ProductOption> products = provider.availableProducts;

    return Scaffold(
      appBar: AppBar(title: const Text("Product Management")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductPage()),
          );

          /// refresh after product created
          if (result == true) {
            loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.precision_manufacturing,
                              size: 30),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Components: ${p.components.length}",
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(product: p),
                              ),
                            );

                            if (result == true) loadProducts();
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
