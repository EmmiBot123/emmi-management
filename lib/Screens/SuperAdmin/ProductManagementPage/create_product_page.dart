import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/productDetails/ProductOption.dart';
import '../../../Providers/Product/ProductProvider.dart';

// ─── Color Palette ───
class _Palette {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF38BDF8);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const danger = Color(0xFFEF4444);
}

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter product name"),
          backgroundColor: _Palette.danger,
        ),
      );
      return;
    }

    /// Build Component List
    final List<ProductComponent> componentList = components
        .map((c) => ProductComponent(
              componentId: _uuid.v4(),
              componentName: c.nameCtrl.text.trim(),
              qtyRequired: int.tryParse(c.qtyCtrl.text.trim()) ?? 0,
              availableStock: 0,
            ))
        .where((c) => c.componentName.isNotEmpty && c.qtyRequired > 0)
        .toList();

    if (componentList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Add at least 1 valid component"),
          backgroundColor: _Palette.danger,
        ),
      );
      return;
    }

    /// ---------- CREATE MODEL ----------
    final product = ProductOption(
      id: _uuid.v4(),
      name: productName,
      types: types,
      components: componentList,
    );

    /// ---------- API ----------
    await context.read<ProductProvider>().addProduct(product);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product Created Successfully"),
          backgroundColor: _Palette.surface,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  /// ============= UI =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _Palette.textPrimary),
        title: const Text(
          "Create Product",
          style: TextStyle(
            color: _Palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Content
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildGlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Product Details",
                      style: TextStyle(
                        color: _Palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: productNameCtrl,
                      label: "Product Name",
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Product Types",
                      style: TextStyle(
                        color: _Palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: typeCtrl,
                            label: "Enter Type (ex: Server)",
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: addType,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Palette.accent.withValues(alpha: 0.2),
                            foregroundColor: _Palette.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (types.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: types.asMap().entries.map((entry) {
                          int index = entry.key;
                          String t = entry.value;

                          return Chip(
                            label: Text(t, style: const TextStyle(color: _Palette.textPrimary)),
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            deleteIcon: const Icon(Icons.close, color: _Palette.textSecondary, size: 16),
                            onDeleted: () => removeType(index),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.transparent),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildGlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Required Components",
                            style: TextStyle(
                              color: _Palette.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: addComponent,
                          icon: const Icon(Icons.add, color: _Palette.accent),
                          label: const Text(
                            "Add",
                            style: TextStyle(color: _Palette.accent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (components.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No components added",
                            style: TextStyle(color: _Palette.textSecondary.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                    ...components.asMap().entries.map((entry) {
                      int index = entry.key;
                      ComponentRow row = entry.value;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: row.nameCtrl,
                                label: "Component Name",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: row.qtyCtrl,
                                label: "Qty",
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: _Palette.danger),
                              onPressed: () => removeComponent(index),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.accent,
                  foregroundColor: _Palette.bg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "Save Product",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _Palette.textPrimary),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _Palette.textSecondary),
        prefixIcon: icon != null ? Icon(icon, color: _Palette.textSecondary, size: 20) : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Palette.accent),
        ),
      ),
    );
  }
}

class ComponentRow {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController qtyCtrl = TextEditingController();
}
