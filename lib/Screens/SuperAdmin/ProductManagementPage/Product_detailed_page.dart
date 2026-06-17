import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../Model/productDetails/ProductOption.dart';
import '../../../Providers/Product/ProductProvider.dart';

// ─── Color Palette ───
class _Palette {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF38BDF8);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

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

  @override
  void dispose() {
    for (var c in qtyControllers) {
      c.dispose();
    }
    for (var c in stockControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// ---------- Save ----------
  Future<void> save() async {
    setState(() => saving = true);

    final ok = await context.read<ProductProvider>().addProduct(product);

    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? "Updated Successfully" : "Update Failed, Try Again"),
          backgroundColor: ok ? _Palette.success : _Palette.danger,
        ),
      );
      if (ok) Navigator.pop(context, true);
    }
  }

  /// ---------- DELETE PRODUCT (ADDED) ----------
  Future<void> deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Palette.surface,
        title: const Text("Delete Product", style: TextStyle(color: _Palette.textPrimary)),
        content: Text(
          "Are you sure you want to delete '${product.name}'?\nThis action cannot be undone.",
          style: const TextStyle(color: _Palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text("Cancel", style: TextStyle(color: _Palette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Palette.danger),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text("Delete", style: TextStyle(color: _Palette.textPrimary)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => saving = true);

    final ok = await context.read<ProductProvider>().deleteProduct(product.id);

    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? "Product Deleted" : "Delete Failed"),
          backgroundColor: ok ? _Palette.success : _Palette.danger,
        ),
      );
      if (ok) Navigator.pop(context, true);
    }
  }

  /// ---------- Add Component ----------
  void addComponentDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Palette.surface,
        title: const Text("Add Component", style: TextStyle(color: _Palette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(nameCtrl, "Component Name"),
            const SizedBox(height: 12),
            _buildDialogTextField(qtyCtrl, "Qty Required Per Unit", isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("Cancel", style: TextStyle(color: _Palette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _Palette.accent),
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
            child: const Text("Add", style: TextStyle(color: _Palette.bg, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _Palette.textPrimary),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _Palette.textSecondary),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _Palette.textPrimary),
        title: Text(
          product.name,
          style: const TextStyle(color: _Palette.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _Palette.danger),
            onPressed: saving ? null : deleteProduct,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, color: _Palette.accent),
            onPressed: saving ? null : save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addComponentDialog,
        backgroundColor: _Palette.accent,
        icon: const Icon(Icons.add, color: _Palette.bg),
        label: const Text("Add Component", style: TextStyle(color: _Palette.bg, fontWeight: FontWeight.bold)),
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
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          // Content
          saving
              ? const Center(child: CircularProgressIndicator(color: _Palette.accent))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildCapacityCard(buildable, blocking),
                    const SizedBox(height: 24),
                    const Text(
                      "Components Configuration",
                      style: TextStyle(color: _Palette.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (product.components.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No Components Added",
                            style: TextStyle(color: _Palette.textSecondary.withValues(alpha: 0.6)),
                          ),
                        ),
                      ),
                    ...product.components.asMap().entries.map((entry) {
                      final index = entry.key;
                      final c = entry.value;
                      return _buildComponentCard(c, index, buildable);
                    }),
                    const SizedBox(height: 80), // spacing for FAB
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildCapacityCard(int buildable, List<ProductComponent> blocking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (buildable > 0 ? _Palette.success : _Palette.danger).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (buildable > 0 ? _Palette.success : _Palette.danger).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  buildable > 0 ? Icons.check_circle_outline : Icons.error_outline,
                  color: buildable > 0 ? _Palette.success : _Palette.danger,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Production Capacity", style: TextStyle(color: _Palette.textSecondary, fontSize: 14)),
                  Text(
                    "$buildable Units",
                    style: TextStyle(
                      color: buildable > 0 ? _Palette.success : _Palette.danger,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            ],
          ),
          if (blocking.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Limiting Components:", style: TextStyle(color: _Palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blocking.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _Palette.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _Palette.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: _Palette.danger, size: 14),
                    const SizedBox(width: 6),
                    Text(c.componentName, style: const TextStyle(color: _Palette.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildComponentCard(ProductComponent c, int index, int buildable) {
    final canBuild = c.qtyRequired == 0 ? 0 : (c.availableStock ~/ c.qtyRequired);
    final missing = getMissingStock(c, buildable);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.componentName,
                  style: const TextStyle(color: _Palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _Palette.danger, size: 20),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInlineTextField(
                  controller: qtyControllers[index],
                  label: "Required Qty",
                  onChanged: (v) {
                    c.qtyRequired = int.tryParse(v) ?? 0;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInlineTextField(
                  controller: stockControllers[index],
                  label: "In Stock",
                  onChanged: (v) {
                    c.availableStock = int.tryParse(v) ?? 0;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Component Capacity", style: TextStyle(color: _Palette.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      "$canBuild units",
                      style: const TextStyle(color: _Palette.success, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                if (missing > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Shortage", style: TextStyle(color: _Palette.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        "$missing needed",
                        style: const TextStyle(color: _Palette.warning, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: _Palette.success, size: 14),
                      SizedBox(width: 4),
                      Text("Sufficient", style: TextStyle(color: _Palette.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInlineTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: _Palette.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _Palette.textSecondary, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Palette.accent),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
