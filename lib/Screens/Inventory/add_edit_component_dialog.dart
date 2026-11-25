import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Inventory/InventoryComponent.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/Inventory/InventoryProvider.dart';
import '../../Providers/Product/ProductProvider.dart';
import '../../Resources/theme_constants.dart';

class AddEditComponentDialog extends StatefulWidget {
  final InventoryComponent? component;
  final String? initialShelf;

  const AddEditComponentDialog({
    super.key,
    this.component,
    this.initialShelf,
  });

  @override
  State<AddEditComponentDialog> createState() => _AddEditComponentDialogState();
}

class _AddEditComponentDialogState extends State<AddEditComponentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _shelfCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _minAlertCtrl;
  late TextEditingController _descCtrl;

  bool _trackQuantity = true;
  String _selectedCategory = 'General';
  bool _isSaving = false;

  final List<String> _categories = [
    'General',
    'Microcontrollers',
    'Sensors',
    'Motors & Actuators',
    'Displays',
    'Electronics',
    'Cables & Wires',
    'Fasteners & Hardware',
    'Tools & Equipment',
    'Packaging & Enclosures',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.component;

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _shelfCtrl = TextEditingController(
      text: c?.shelfNumber ?? widget.initialShelf ?? '',
    );
    _qtyCtrl = TextEditingController(
      text: c?.quantity != null ? c!.quantity.toString() : '',
    );
    _unitCtrl = TextEditingController(text: c?.unit ?? 'pcs');
    _minAlertCtrl = TextEditingController(
      text: c?.minStockAlert != null ? c!.minStockAlert.toString() : '',
    );
    _descCtrl = TextEditingController(text: c?.description ?? '');

    _trackQuantity = c?.quantity != null || c == null;

    if (c != null && _categories.contains(c.category)) {
      _selectedCategory = c.category;
    } else if (c != null && c.category.isNotEmpty) {
      _categories.insert(0, c.category);
      _selectedCategory = c.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shelfCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _minAlertCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final inventoryProvider = context.read<InventoryProvider>();

    int? qty;
    if (_trackQuantity) {
      final qtyText = _qtyCtrl.text.trim();
      if (qtyText.isNotEmpty) {
        qty = int.tryParse(qtyText);
      }
    }

    int? minAlert;
    final alertText = _minAlertCtrl.text.trim();
    if (alertText.isNotEmpty) {
      minAlert = int.tryParse(alertText);
    }

    final isEdit = widget.component != null;
    final now = DateTime.now();

    final componentToSave = InventoryComponent(
      id: widget.component?.id ?? '',
      name: _nameCtrl.text.trim(),
      shelfNumber: _shelfCtrl.text.trim(),
      quantity: qty,
      category: _selectedCategory,
      unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      minStockAlert: minAlert,
      createdAt: widget.component?.createdAt ?? now,
      updatedAt: now,
    );

    final auth = context.read<AuthProvider>();
    final performedBy = auth.name?.isNotEmpty == true
        ? auth.name!
        : (auth.email?.isNotEmpty == true ? auth.email! : 'Staff');

    bool success;
    if (isEdit) {
      success = await inventoryProvider.updateComponent(
        componentToSave,
        performedBy: performedBy,
      );
    } else {
      success = await inventoryProvider.addComponent(
        componentToSave,
        performedBy: performedBy,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  isEdit
                      ? 'Component updated successfully'
                      : 'Component added to Shelf ${_shelfCtrl.text.trim()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Text(
              inventoryProvider.errorMessage ?? 'Failed to save component',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.component != null;
    final inventoryProvider = context.watch<InventoryProvider>();
    final productProvider = context.watch<ProductProvider>();

    // Suggestion lists
    final existingShelves = inventoryProvider.uniqueShelves;
    final existingProductComponents = <String>{};
    for (final p in productProvider.availableProducts) {
      for (final c in p.components) {
        if (c.componentName.trim().isNotEmpty) {
          existingProductComponents.add(c.componentName.trim());
        }
      }
    }

    final dialogWidth = MediaQuery.of(context).size.width.clamp(320.0, 560.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: 0.5),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.add_box_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? "Edit Component" : "Add New Component",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Specify component name, shelf location & optional quantity",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textSecondary,
                          hoverColor: Colors.white.withValues(alpha: 0.1),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Form Body ──
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      shrinkWrap: true,
                      children: [
                        // 1. Component Name Field with Autocomplete
                        _buildSectionLabel(
                          label: "Component Name",
                          isRequired: true,
                          icon: Icons.precision_manufacturing_rounded,
                        ),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _nameCtrl.text),
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return existingProductComponents.where((option) =>
                                option.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    ));
                          },
                          onSelected: (selection) {
                            _nameCtrl.text = selection;
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onFieldSubmitted) {
                            // Sync controller with our local controller
                            controller.addListener(() {
                              _nameCtrl.text = controller.text;
                            });
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(
                                hint: "e.g. ESP32 DevKit, Servo SG90, Resistor 10k",
                                prefixIcon: Icons.memory_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "Component name is required";
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. Shelf Number Field (REQUIRED)
                        _buildSectionLabel(
                          label: "Shelf Number / Location",
                          isRequired: true,
                          icon: Icons.storage_rounded,
                          tooltip:
                              "The exact shelf or rack where this component is physically placed",
                        ),
                        const SizedBox(height: 8),
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _shelfCtrl.text),
                          optionsBuilder: (textEditingValue) {
                            if (existingShelves.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            if (textEditingValue.text.isEmpty) {
                              return existingShelves.take(6);
                            }
                            return existingShelves.where((s) => s
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (selection) {
                            _shelfCtrl.text = selection;
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onFieldSubmitted) {
                            controller.addListener(() {
                              _shelfCtrl.text = controller.text;
                            });
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _inputDecoration(
                                hint: "e.g. Shelf A-04, Rack 2 / Bin C",
                                prefixIcon: Icons.location_on_rounded,
                                prefixIconColor: const Color(0xFF38BDF8),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "Shelf number is required";
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        if (existingShelves.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Quick pick:",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ...existingShelves.take(5).map((shelf) => InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () {
                                      setState(() {
                                        _shelfCtrl.text = shelf;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        shelf,
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // 3. Optional Quantity Card with Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _trackQuantity
                                  ? AppColors.accent.withValues(alpha: 0.4)
                                  : AppColors.surfaceLight,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pin_outlined,
                                        size: 18,
                                        color: _trackQuantity
                                            ? AppColors.accent
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Quantity",
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          "OPTIONAL",
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: _trackQuantity,
                                    activeTrackColor: AppColors.accent,
                                    onChanged: (val) {
                                      setState(() {
                                        _trackQuantity = val;
                                        if (!val) {
                                          _qtyCtrl.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _trackQuantity
                                    ? "Tracking quantity in stock for this component"
                                    : "Quantity untracked — tracking shelf location only",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              if (_trackQuantity) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller: _qtyCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: "e.g. 50 (or leave 0)",
                                          prefixIcon:
                                              Icons.numbers_rounded,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _unitCtrl,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: "Unit (pcs)",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _minAlertCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: "Low stock alert threshold (optional)",
                                    prefixIcon:
                                        Icons.warning_amber_rounded,
                                    prefixIconColor:
                                        const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Category & Details
                        _buildSectionLabel(
                          label: "Category",
                          icon: Icons.category_rounded,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 5. Description / Specs / Notes
                        _buildSectionLabel(
                          label: "Description / Specs (Optional)",
                          icon: Icons.notes_rounded,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: _inputDecoration(
                            hint: "Pinout, operating voltage, supplier, or shelf bin notes...",
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Actions Footer ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: 0.5),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEdit
                                          ? Icons.save_rounded
                                          : Icons.add_circle_outline_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEdit ? "Save Changes" : "Add Component",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required String label,
    bool isRequired = false,
    IconData? icon,
    String? tooltip,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        if (isRequired)
          const Text(
            " *",
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            child: const Icon(
              Icons.info_outline,
              size: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Color? prefixIconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.7),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 18,
              color: prefixIconColor ?? AppColors.textSecondary,
            )
          : null,
      filled: true,
      fillColor: AppColors.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
