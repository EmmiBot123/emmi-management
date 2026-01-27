import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../Model/productDetails/ProductOption.dart';
import '../../../Providers/Product/ProductProvider.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductOption product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late ProductOption product;
  bool saving = false;

  final List<TextEditingController> qtyControllers = [];
  final List<TextEditingController> stockControllers = [];

  @override
  void initState() {
    super.initState();
    product = widget.product;
    initControllers();
  }

  void initControllers() {
    qtyControllers.clear();
    stockControllers.clear();

    for (var c in product.components) {
      qtyControllers.add(TextEditingController(text: c.qtyRequired.toString()));
      stockControllers
          .add(TextEditingController(text: c.availableStock.toString()));
    }
  }

  /// ---------- Save ----------
  Future<void> save() async {
    saving = true;
    setState(() {});

    final ok = await context.read<ProductProvider>().addProduct(product);

    saving = false;
    setState(() {});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Updated Successfully" : "Update Failed, Try Again"),
      ),
    );

    if (ok) Navigator.pop(context, true);
  }

  /// ---------- DELETE PRODUCT (ADDED) ----------
  Future<void> deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text(
          "Are you sure you want to delete '${product.name}'?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    saving = true;
    setState(() {});
    print("above all");

    final ok = await context.read<ProductProvider>().deleteProduct(product.id);

    saving = false;
    setState(() {});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "Product Deleted" : "Delete Failed")),
    );

    if (ok) Navigator.pop(context, true);
  }

  /// ---------- Add Component ----------
  void addComponentDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Component"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Component Name"),
            ),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Qty Required Per Unit"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;

              final newComponent = ProductComponent(
                componentId: DateTime.now().millisecondsSinceEpoch.toString(),
                componentName: nameCtrl.text.trim(),
                qtyRequired: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                availableStock: 0,
              );

              product.components.add(newComponent);
              qtyControllers.add(TextEditingController(
                  text: newComponent.qtyRequired.toString()));
              stockControllers.add(TextEditingController(
                  text: newComponent.availableStock.toString()));

              setState(() {});
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  /// ---------- Buildable Count ----------
  int getBuildableCount() {
    if (product.components.isEmpty) return 0;

    int minBuild = 999999;

    for (var c in product.components) {
      if (c.qtyRequired <= 0) return 0;

      final canBuild = c.availableStock ~/ c.qtyRequired;
      if (canBuild < minBuild) minBuild = canBuild;
    }

    return minBuild == 999999 ? 0 : minBuild;
  }

  /// ---------- Blocking Components ----------
  List<ProductComponent> getBlockingComponents() {
    return product.components.where((c) {
      if (c.qtyRequired <= 0) return true;
      return c.availableStock < c.qtyRequired;
    }).toList();
  }

  /// ---------- Missing Stock ----------
  int getMissingStock(ProductComponent c, int buildable) {
    final requiredForFullUse = buildable * c.qtyRequired;
    final missing = requiredForFullUse - c.availableStock;
    return missing > 0 ? missing : 0;
  }

  @override
  Widget build(BuildContext context) {
    final buildable = getBuildableCount();
    final blocking = getBlockingComponents();

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: saving ? null : deleteProduct,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saving ? null : save,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addComponentDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Component"),
      ),
      body: saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Product: ${product.name}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Production Capacity",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          "You can build: $buildable units",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: buildable > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        if (blocking.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text(
                            "Limiting Components:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          ...blocking.map(
                            (c) => Text(
                              "• ${c.componentName}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Components",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (product.components.isEmpty)
                  const Center(child: Text("No Components Added")),
                ...product.components.asMap().entries.map((entry) {
                  final index = entry.key;
                  final c = entry.value;

                  final canBuild = c.qtyRequired == 0
                      ? 0
                      : (c.availableStock ~/ c.qtyRequired);
                  final missing = getMissingStock(c, buildable);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.componentName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    qtyControllers.removeAt(index);
                                    stockControllers.removeAt(index);
                                    product.components.removeAt(index);
                                  });
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: qtyControllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Qty Required",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) {
                                    c.qtyRequired = int.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: stockControllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Available Stock",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) {
                                    c.availableStock = int.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Can Build: $canBuild units",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green),
                                ),
                                if (missing > 0)
                                  Text(
                                    "Needs $missing more to fully utilize product",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red),
                                  )
                                else
                                  const Text(
                                    "Sufficient stock",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green),
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
