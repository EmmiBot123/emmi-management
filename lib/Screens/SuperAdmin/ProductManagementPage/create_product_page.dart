import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/productDetails/ProductOption.dart';
import '../../../Providers/Product/ProductProvider.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final TextEditingController productNameCtrl = TextEditingController();

  /// ---------- TYPES ----------
  final TextEditingController typeCtrl = TextEditingController();
  List<String> types = [];

  List<ComponentRow> components = [];

  final Uuid _uuid = const Uuid();

  void addComponent() {
    setState(() => components.add(ComponentRow()));
  }

  void removeComponent(int index) {
    setState(() => components.removeAt(index));
  }

  void addType() {
    final text = typeCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      types.add(text);
      typeCtrl.clear();
    });
  }

  void removeType(int index) {
    setState(() => types.removeAt(index));
  }

  /// ============= SAVE ============
  void save() async {
    final productName = productNameCtrl.text.trim();

    if (productName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter product name")));
      return;
    }

    /// Build Component List
    final List<ProductComponent> componentList = components
        .map((c) => ProductComponent(
              componentId: _uuid.v4(), // ✅ UUID ADDED
              componentName: c.nameCtrl.text.trim(),
              qtyRequired: int.tryParse(c.qtyCtrl.text.trim()) ?? 0,
              availableStock: 0,
            ))
        .where((c) => c.componentName.isNotEmpty && c.qtyRequired > 0)
        .toList();

    if (componentList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add at least 1 valid component")));
      return;
    }

    /// ---------- CREATE MODEL ----------
    final product = ProductOption(
      id: _uuid.v4(), // ✅ UUID ADDED
      name: productName,
      types: types,
      components: componentList,
    );

    /// ---------- API ----------
    await context.read<ProductProvider>().addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product Created Successfully")),
    );

    Navigator.pop(context, true);
  }

  /// ============= UI =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Product")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// PRODUCT NAME
          TextField(
            controller: productNameCtrl,
            decoration: const InputDecoration(
              labelText: "Product Name",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          /// ---------- TYPES ----------
          const Text(
            "Product Types",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: "Enter Type (ex: Server / Standalone)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: addType,
                child: const Text("Add"),
              )
            ],
          ),

          const SizedBox(height: 10),

          if (types.isEmpty) const Text("No types added"),
          if (types.isNotEmpty)
            Wrap(
              spacing: 8,
              children: types.asMap().entries.map((entry) {
                int index = entry.key;
                String t = entry.value;

                return Chip(
                  label: Text(t),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => removeType(index),
                );
              }).toList(),
            ),

          const Divider(height: 30),

          /// ---------- COMPONENTS ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Required Components (Per Device)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: addComponent,
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),

          if (components.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: Text("No components added")),
            ),

          ...components.asMap().entries.map((entry) {
            int index = entry.key;
            ComponentRow row = entry.value;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    /// Component Name
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: row.nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Component Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// Qty Required
                    Expanded(
                      child: TextField(
                        controller: row.qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Qty / Device",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeComponent(index),
                    )
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Text("Save Product"),
          ),
        ],
      ),
    );
  }
}

class ComponentRow {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController qtyCtrl = TextEditingController();
}
