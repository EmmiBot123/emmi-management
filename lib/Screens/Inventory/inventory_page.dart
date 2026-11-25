import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Inventory/InventoryComponent.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/Inventory/InventoryProvider.dart';
import '../../Providers/Product/ProductProvider.dart';
import '../../Resources/theme_constants.dart';
import 'add_edit_component_dialog.dart';
import 'inventory_history_sheet.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedShelf = 'ALL';
  String _selectedCategory = 'ALL';
  String _stockFilter = 'ALL'; // ALL, TRACKED, UNTRACKED, LOW_STOCK
  String _sortBy = 'SHELF'; // SHELF, NAME, QTY_DESC, QTY_ASC
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchComponents();
      context.read<ProductProvider>().fetchAvailableProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getCurrentUserName() {
    final auth = context.read<AuthProvider>();
    if (auth.name != null && auth.name!.trim().isNotEmpty) {
      return auth.name!.trim();
    }
    if (auth.email != null && auth.email!.trim().isNotEmpty) {
      return auth.email!.trim();
    }
    return 'Staff';
  }

  List<InventoryComponent> _getFilteredComponents(
    List<InventoryComponent> rawList,
  ) {
    return rawList.where((c) {
      // 1. Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesShelf = c.shelfNumber.toLowerCase().contains(q);
        final matchesCategory = c.category.toLowerCase().contains(q);
        final matchesDesc = c.description.toLowerCase().contains(q);
        if (!matchesName && !matchesShelf && !matchesCategory && !matchesDesc) {
          return false;
        }
      }

      // 2. Shelf filter
      if (_selectedShelf != 'ALL') {
        if (c.shelfNumber.trim().toLowerCase() !=
            _selectedShelf.trim().toLowerCase()) {
          return false;
        }
      }

      // 3. Category filter
      if (_selectedCategory != 'ALL') {
        if (c.category.trim().toLowerCase() !=
            _selectedCategory.trim().toLowerCase()) {
          return false;
        }
      }

      // 4. Stock status filter
      if (_stockFilter == 'TRACKED') {
        if (!c.hasQuantity) return false;
      } else if (_stockFilter == 'UNTRACKED') {
        if (c.hasQuantity) return false;
      } else if (_stockFilter == 'LOW_STOCK') {
        if (!c.isLowStock && !c.isOutOfStock) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'SHELF':
            final shelfComp = a.shelfNumber
                .toLowerCase()
                .compareTo(b.shelfNumber.toLowerCase());
            if (shelfComp != 0) return shelfComp;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case 'NAME':
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case 'QTY_DESC':
            final qA = a.quantity ?? -1;
            final qB = b.quantity ?? -1;
            return qB.compareTo(qA);
          case 'QTY_ASC':
            final qA = a.quantity ?? 999999;
            final qB = b.quantity ?? 999999;
            return qA.compareTo(qB);
          default:
            return 0;
        }
      });
  }

  void _openAddEditDialog([InventoryComponent? component, String? initialShelf]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddEditComponentDialog(
        component: component,
        initialShelf: initialShelf ?? (_selectedShelf != 'ALL' ? _selectedShelf : null),
      ),
    );
  }

  void _promptDelete(InventoryComponent component) {
    final performedBy = _getCurrentUserName();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceLight),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Delete Component",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to remove '${component.name}' from Shelf ${component.shelfNumber}?",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<InventoryProvider>().deleteComponent(
                    component.id,
                    performedBy: performedBy,
                  );
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFEF4444),
                    content: Text("Component removed from inventory"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _promptQuickShelfMove(InventoryComponent component) {
    final ctrl = TextEditingController(text: component.shelfNumber);
    final noteCtrl = TextEditingController();
    final performedBy = _getCurrentUserName();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceLight),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drive_file_move_outline,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Move to New Shelf",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Moving '${component.name}' from current location:",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Current: Shelf ${component.shelfNumber}",
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: "New Shelf Number *",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: "e.g. Shelf B-05, Rack 2 / Bin C",
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppColors.bg,
                prefixIcon: const Icon(
                  Icons.storage_rounded,
                  color: Color(0xFF38BDF8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: "Reason / Note (Optional)",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: "e.g. Workshop reorganization, kit prep...",
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppColors.bg,
                prefixIcon: const Icon(
                  Icons.notes_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newShelf = ctrl.text.trim();
              if (newShelf.isEmpty) return;
              Navigator.pop(ctx);
              await context.read<InventoryProvider>().updateShelf(
                    component.id,
                    newShelf,
                    performedBy: performedBy,
                    reason: noteCtrl.text.trim(),
                  );
            },
            child: const Text("Confirm Move"),
          ),
        ],
      ),
    );
  }

  void _promptSetQuantity(InventoryComponent component) {
    final ctrl = TextEditingController(
      text: component.quantity?.toString() ?? '',
    );
    final noteCtrl = TextEditingController();
    final performedBy = _getCurrentUserName();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceLight),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pin_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Update Quantity",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Component: ${component.name} (Shelf ${component.shelfNumber})",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: "Quantity in Stock",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: "Leave empty to make untracked",
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                suffixText: component.unit,
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: "Reason / Note (Optional)",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: "e.g. Restock shipment, kit build, damaged...",
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppColors.bg,
                prefixIcon: const Icon(
                  Icons.notes_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final text = ctrl.text.trim();
              final newQty = text.isEmpty ? null : int.tryParse(text);
              Navigator.pop(ctx);
              await context.read<InventoryProvider>().setQuantity(
                    component.id,
                    newQty,
                    performedBy: performedBy,
                    reason: noteCtrl.text.trim(),
                  );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _handleImportFromProducts() async {
    final productProvider = context.read<ProductProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final performedBy = _getCurrentUserName();

    if (productProvider.availableProducts.isEmpty) {
      await productProvider.fetchAvailableProducts();
    }

    final totalComponentsInProducts = productProvider.availableProducts
        .expand((p) => p.components)
        .length;

    if (totalComponentsInProducts == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No product components found to import."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceLight),
        ),
        title: const Text(
          "Import Product Components",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will automatically scan all products in the database and create inventory items for any components that are not yet catalogued. They will be placed in 'Shelf A-01' by default so you can assign their shelf numbers.\n\nContinue?",
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Import Now"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final imported = await inventoryProvider.importFromProducts(
        productProvider.availableProducts,
        performedBy: performedBy,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Text(
              imported > 0
                  ? "Imported $imported new component(s) from products!"
                  : "All product components are already in the inventory.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final allComponents = inventoryProvider.components;
    final filteredComponents = _getFilteredComponents(allComponents);
    final isWide = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(),
        backgroundColor: AppColors.accent,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          "Add Component",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: AppColors.surface,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                    ),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  )
                : null,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Component Inventory",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "Shelves, Hardware & Stock Management",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Stock Movement & Audit Trail",
                icon: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF38BDF8),
                ),
                onPressed: () {
                  InventoryHistorySheet.show(context);
                },
              ),
              IconButton(
                tooltip: "Import from Products",
                icon: const Icon(
                  Icons.download_for_offline_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: _handleImportFromProducts,
              ),
              IconButton(
                tooltip: "Refresh",
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  inventoryProvider.fetchComponents();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Main Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KPI Stats Cards
                  _buildKpiMetricsRow(inventoryProvider, isWide, isMobile),
                  const SizedBox(height: 24),

                  // 2. Search & Controls Bar
                  _buildSearchAndFilterControls(
                    inventoryProvider,
                    filteredComponents.length,
                    isMobile,
                  ),
                  const SizedBox(height: 16),

                  // 3. Category & Shelf Filter Chips
                  _buildShelfAndCategoryChips(inventoryProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Components Grid or List ──
          if (inventoryProvider.isLoading && allComponents.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (filteredComponents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(allComponents.isEmpty),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
              ).copyWith(bottom: 90),
              sliver: _isGridView
                  ? SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide
                            ? 3
                            : (isMobile ? 1 : 2),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.65 : (isWide ? 1.45 : 1.35),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildComponentCard(
                            filteredComponents[index],
                          );
                        },
                        childCount: filteredComponents.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildComponentListItem(
                            filteredComponents[index],
                          );
                        },
                        childCount: filteredComponents.length,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  KPI Metrics
  // ═══════════════════════════════════════════════════════
  Widget _buildKpiMetricsRow(
    InventoryProvider provider,
    bool isWide,
    bool isMobile,
  ) {
    final metrics = [
      _MetricData(
        label: "Unique Components",
        value: provider.totalComponents.toString(),
        icon: Icons.precision_manufacturing_rounded,
        color: const Color(0xFF6C63FF),
        subtext: "catalogued",
      ),
      _MetricData(
        label: "Active Shelves",
        value: provider.totalShelves.toString(),
        icon: Icons.storage_rounded,
        color: const Color(0xFF38BDF8),
        subtext: "storage locations",
      ),
      _MetricData(
        label: "Total Units Tracked",
        value: provider.totalStockUnits.toString(),
        icon: Icons.inventory_rounded,
        color: const Color(0xFF10B981),
        subtext: "across all bins",
      ),
      _MetricData(
        label: "Low Stock Alerts",
        value: provider.lowStockCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF59E0B),
        subtext: "requires restock",
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: metrics.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 200,
            child: _buildMetricCard(metrics[i]),
          ),
        ),
      );
    }

    return Row(
      children: metrics.map((m) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildMetricCard(m),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: m.color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  m.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  m.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Search & Filter Controls
  // ═══════════════════════════════════════════════════════
  Widget _buildSearchAndFilterControls(
    InventoryProvider provider,
    int filteredCount,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search component name, shelf, category, notes...",
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.surfaceLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.surfaceLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.sort_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'SHELF',
                        child: Text("Sort: Shelf"),
                      ),
                      DropdownMenuItem(
                        value: 'NAME',
                        child: Text("Sort: Name"),
                      ),
                      DropdownMenuItem(
                        value: 'QTY_DESC',
                        child: Text("Qty: High to Low"),
                      ),
                      DropdownMenuItem(
                        value: 'QTY_ASC',
                        child: Text("Qty: Low to High"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _sortBy = v);
                    },
                  ),
                ),
              ),

              if (!isMobile) ...[
                const SizedBox(width: 8),
                // Grid / List toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: _isGridView
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _isGridView = true),
                        tooltip: "Grid View",
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.view_list_rounded,
                          size: 20,
                          color: !_isGridView
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _isGridView = false),
                        tooltip: "List View",
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Stock filters (All, Tracked, Untracked, Low Stock)
          Row(
            children: [
              Text(
                "Showing $filteredCount of ${provider.totalComponents} items",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildStockFilterPill("ALL", "All Stock"),
              const SizedBox(width: 6),
              _buildStockFilterPill("TRACKED", "Tracked Qty"),
              const SizedBox(width: 6),
              _buildStockFilterPill("UNTRACKED", "Untracked"),
              const SizedBox(width: 6),
              _buildStockFilterPill(
                "LOW_STOCK",
                "Low Stock (${provider.lowStockCount})",
                isWarning: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockFilterPill(
    String key,
    String label, {
    bool isWarning = false,
  }) {
    final isSelected = _stockFilter == key;
    final color = isWarning ? const Color(0xFFF59E0B) : AppColors.accent;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _stockFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? color
                : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Shelf & Category Chips
  // ═══════════════════════════════════════════════════════
  Widget _buildShelfAndCategoryChips(InventoryProvider provider) {
    final shelves = provider.uniqueShelves;
    final categories = provider.uniqueCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelves Horizontal Row
        Row(
          children: [
            const Icon(
              Icons.storage_rounded,
              size: 16,
              color: Color(0xFF38BDF8),
            ),
            const SizedBox(width: 6),
            const Text(
              "Filter by Shelf:",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      label: "All Shelves",
                      isSelected: _selectedShelf == 'ALL',
                      onTap: () => setState(() => _selectedShelf = 'ALL'),
                      icon: Icons.all_inclusive_rounded,
                      activeColor: const Color(0xFF38BDF8),
                    ),
                    ...shelves.map((s) {
                      final count = provider.components
                          .where((c) =>
                              c.shelfNumber.trim().toLowerCase() ==
                              s.trim().toLowerCase())
                          .length;
                      return _buildChip(
                        label: "$s ($count)",
                        isSelected: _selectedShelf == s,
                        onTap: () => setState(() => _selectedShelf = s),
                        activeColor: const Color(0xFF38BDF8),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          // Categories Horizontal Row
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              const Text(
                "Category:",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip(
                        label: "All Categories",
                        isSelected: _selectedCategory == 'ALL',
                        onTap: () => setState(() => _selectedCategory = 'ALL'),
                        activeColor: AppColors.accent,
                      ),
                      ...categories.map((cat) {
                        return _buildChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                          activeColor: AppColors.accent,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = AppColors.accent,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : AppColors.surfaceLight,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? activeColor : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Component Card (Grid View)
  // ═══════════════════════════════════════════════════════
  Widget _buildComponentCard(InventoryComponent c) {
    final hasQty = c.hasQuantity;
    final isLow = c.isLowStock;
    final isOut = c.isOutOfStock;
    final performedBy = _getCurrentUserName();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOut
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : (isLow
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : AppColors.surfaceLight),
          width: (isOut || isLow) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Name + Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.surfaceLight,
                          ),
                        ),
                        child: Text(
                          c.category,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  onSelected: (val) {
                    if (val == 'HISTORY') {
                      InventoryHistorySheet.show(context, targetComponent: c);
                    }
                    if (val == 'EDIT') _openAddEditDialog(c);
                    if (val == 'MOVE') _promptQuickShelfMove(c);
                    if (val == 'QTY') _promptSetQuantity(c);
                    if (val == 'DELETE') _promptDelete(c);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'HISTORY',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18, color: Color(0xFF38BDF8)),
                          SizedBox(width: 10),
                          Text("Movement History", style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'EDIT',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                          SizedBox(width: 10),
                          Text("Edit Details", style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'MOVE',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_move_outlined, size: 18, color: Color(0xFF38BDF8)),
                          SizedBox(width: 10),
                          Text("Move Shelf", style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'QTY',
                      child: Row(
                        children: [
                          Icon(Icons.pin_outlined, size: 18, color: Color(0xFF10B981)),
                          SizedBox(width: 10),
                          Text("Set Quantity", style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'DELETE',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Text("Delete", style: TextStyle(color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.surfaceLight),

          // Main Body: Shelf Number (REQUIRED) & Quantity (OPTIONAL)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. Shelf Number Badge (highlighted)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => _selectedShelf = c.shelfNumber);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage_rounded,
                            color: Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Shelf: ${c.shelfNumber}",
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Quantity Row
                  if (hasQty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.quantity.toString(),
                                  style: TextStyle(
                                    color: isOut
                                        ? const Color(0xFFEF4444)
                                        : (isLow
                                            ? const Color(0xFFF59E0B)
                                            : AppColors.textPrimary),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c.unit,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isOut)
                              const Text(
                                "Out of Stock",
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else if (isLow)
                              Text(
                                "Low stock (Min: ${c.minStockAlert})",
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              const Text(
                                "In Stock",
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),

                        // Micro Stepper (+ / -) with Audit Logging
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  context.read<InventoryProvider>().adjustQuantity(
                                        c.id,
                                        -1,
                                        performedBy: performedBy,
                                        reason: 'Quick deduction (-1)',
                                      );
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 16,
                                color: AppColors.surfaceLight,
                              ),
                              InkWell(
                                onTap: () {
                                  context.read<InventoryProvider>().adjustQuantity(
                                        c.id,
                                        1,
                                        performedBy: performedBy,
                                        reason: 'Quick restock (+1)',
                                      );
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Quantity Untracked",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _promptSetQuantity(c),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add, size: 12),
                          label: const Text(
                            "Track Qty",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),

                  // Description snippet if available
                  if (c.description.isNotEmpty)
                    Text(
                      c.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Component Item (List View)
  // ═══════════════════════════════════════════════════════
  Widget _buildComponentListItem(InventoryComponent c) {
    final performedBy = _getCurrentUserName();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          // Shelf badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storage_rounded,
                  color: Color(0xFF38BDF8),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  c.shelfNumber,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Name and Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${c.category}${c.description.isNotEmpty ? ' • ${c.description}' : ''}",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Quantity
          if (c.hasQuantity) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${c.quantity} ${c.unit}",
                  style: TextStyle(
                    color: c.isOutOfStock
                        ? const Color(0xFFEF4444)
                        : (c.isLowStock
                            ? const Color(0xFFF59E0B)
                            : AppColors.textPrimary),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  c.isOutOfStock
                      ? "Out of Stock"
                      : (c.isLowStock ? "Low Stock" : "In Stock"),
                  style: TextStyle(
                    color: c.isOutOfStock
                        ? const Color(0xFFEF4444)
                        : (c.isLowStock
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981)),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Quick stepper
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    context.read<InventoryProvider>().adjustQuantity(
                          c.id,
                          -1,
                          performedBy: performedBy,
                          reason: 'Quick deduction (-1)',
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: AppColors.accent,
                  onPressed: () {
                    context.read<InventoryProvider>().adjustQuantity(
                          c.id,
                          1,
                          performedBy: performedBy,
                          reason: 'Quick restock (+1)',
                        );
                  },
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Untracked",
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),

          // Action menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.surfaceLight),
            ),
            onSelected: (val) {
              if (val == 'HISTORY') {
                InventoryHistorySheet.show(context, targetComponent: c);
              }
              if (val == 'EDIT') _openAddEditDialog(c);
              if (val == 'MOVE') _promptQuickShelfMove(c);
              if (val == 'QTY') _promptSetQuantity(c);
              if (val == 'DELETE') _promptDelete(c);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'HISTORY',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 18, color: Color(0xFF38BDF8)),
                    SizedBox(width: 10),
                    Text("Movement History", style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'EDIT',
                child: Text("Edit", style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'MOVE',
                child: Text("Move Shelf", style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'QTY',
                child: Text("Set Quantity", style: TextStyle(color: AppColors.textPrimary)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'DELETE',
                child: Text("Delete", style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Empty State
  // ═══════════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDatabaseEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Icon(
                isDatabaseEmpty
                    ? Icons.storage_rounded
                    : Icons.filter_alt_off_rounded,
                size: 54,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isDatabaseEmpty
                  ? "No Components in Inventory"
                  : "No Components Match Your Filter",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDatabaseEmpty
                  ? "Start by adding workshop components with their shelf numbers and optional quantities."
                  : "Try clearing search keywords or selecting 'All Shelves'.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            if (isDatabaseEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openAddEditDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add First Component"),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _handleImportFromProducts,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Import from Products"),
                  ),
                ],
              )
            else
              TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedShelf = 'ALL';
                    _selectedCategory = 'ALL';
                    _stockFilter = 'ALL';
                  });
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text("Reset All Filters"),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtext;

  _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtext,
  });
}
