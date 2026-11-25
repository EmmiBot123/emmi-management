import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../Model/Inventory/InventoryComponent.dart';
import '../../Model/Inventory/InventoryLog.dart';
import '../../Model/productDetails/ProductOption.dart';

class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<InventoryComponent> _components = [];
  List<InventoryLog> _logs = [];
  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _streamSubscription;
  StreamSubscription<QuerySnapshot>? _logsSubscription;

  List<InventoryComponent> get components => _components;
  List<InventoryLog> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isLoadingLogs => _isLoadingLogs;
  String? get errorMessage => _errorMessage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inventory_components');

  CollectionReference<Map<String, dynamic>> get _logsCollection =>
      _firestore.collection('inventory_logs');

  InventoryProvider() {
    initRealtimeListener();
    initLogsListener();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _logsSubscription?.cancel();
    super.dispose();
  }

  /// Initialize real-time updates for components
  void initRealtimeListener() {
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();
    _streamSubscription = _collection
        .orderBy('name', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        _components = snapshot.docs.map((doc) {
          final data = doc.data();
          return InventoryComponent.fromJson(data, doc.id);
        }).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print("❌ InventoryProvider stream error: $error");
        }
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Initialize real-time updates for movement audit logs
  void initLogsListener() {
    _isLoadingLogs = true;
    notifyListeners();

    _logsSubscription?.cancel();
    _logsSubscription = _logsCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        _logs = snapshot.docs.map((doc) {
          return InventoryLog.fromJson(doc.data(), doc.id);
        }).toList();
        _isLoadingLogs = false;
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print("❌ Inventory logs stream error: $error");
        }
        _isLoadingLogs = false;
        notifyListeners();
      },
    );
  }

  /// Fetch components manually if needed
  Future<void> fetchComponents() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _collection.orderBy('name').get();
      _components = snapshot.docs.map((doc) {
        return InventoryComponent.fromJson(doc.data(), doc.id);
      }).toList();
      _errorMessage = null;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching inventory components: $e");
      }
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record an audit log entry
  Future<void> _recordLog(InventoryLog log) async {
    try {
      final docId = log.id.isNotEmpty ? log.id : _uuid.v4();
      final fullLog = InventoryLog(
        id: docId,
        componentId: log.componentId,
        componentName: log.componentName,
        actionType: log.actionType,
        previousShelf: log.previousShelf,
        newShelf: log.newShelf,
        previousQuantity: log.previousQuantity,
        newQuantity: log.newQuantity,
        quantityChange: log.quantityChange,
        note: log.note,
        performedBy: log.performedBy,
        timestamp: log.timestamp,
      );

      await _logsCollection.doc(docId).set(fullLog.toJson());
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Failed to record inventory audit log: $e");
      }
    }
  }

  /// Get specific audit logs for a single component
  List<InventoryLog> getLogsForComponent(String componentId) {
    return _logs.where((l) => l.componentId == componentId).toList();
  }

  /// Add a new component & record creation log
  Future<bool> addComponent(
    InventoryComponent component, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final docId = component.id.isNotEmpty ? component.id : _uuid.v4();
      final now = DateTime.now();

      final newComponent = component.copyWith(
        id: docId,
        createdAt: component.createdAt ?? now,
        updatedAt: now,
      );

      await _collection.doc(docId).set(newComponent.toJson());

      // Optimistic update
      final index = _components.indexWhere((c) => c.id == docId);
      if (index != -1) {
        _components[index] = newComponent;
      } else {
        _components.add(newComponent);
        _components.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
      notifyListeners();

      // Record Audit Log
      await _recordLog(
        InventoryLog(
          componentId: docId,
          componentName: newComponent.name,
          actionType: InventoryActionType.created,
          newShelf: newComponent.shelfNumber,
          newQuantity: newComponent.quantity,
          performedBy: performedBy,
          note: reason.isNotEmpty ? reason : 'Initial component creation',
          timestamp: now,
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error adding component: $e");
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing component & record log
  Future<bool> updateComponent(
    InventoryComponent component, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final now = DateTime.now();
      final index = _components.indexWhere((c) => c.id == component.id);
      final prev = index != -1 ? _components[index] : null;

      final updated = component.copyWith(updatedAt: now);

      await _collection.doc(component.id).set(
            updated.toJson(),
            SetOptions(merge: true),
          );

      if (index != -1) {
        _components[index] = updated;
        notifyListeners();
      }

      // Record Log
      await _recordLog(
        InventoryLog(
          componentId: component.id,
          componentName: component.name,
          actionType: (prev != null && prev.shelfNumber != component.shelfNumber)
              ? InventoryActionType.shelfMoved
              : InventoryActionType.updated,
          previousShelf: prev?.shelfNumber,
          newShelf: component.shelfNumber,
          previousQuantity: prev?.quantity,
          newQuantity: component.quantity,
          performedBy: performedBy,
          note: reason.isNotEmpty ? reason : 'Component details updated',
          timestamp: now,
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating component: $e");
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a component & record log
  Future<bool> deleteComponent(
    String id, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final index = _components.indexWhere((c) => c.id == id);
      final comp = index != -1 ? _components[index] : null;

      await _collection.doc(id).delete();
      _components.removeWhere((c) => c.id == id);
      notifyListeners();

      if (comp != null) {
        await _recordLog(
          InventoryLog(
            componentId: id,
            componentName: comp.name,
            actionType: InventoryActionType.deleted,
            previousShelf: comp.shelfNumber,
            previousQuantity: comp.quantity,
            performedBy: performedBy,
            note: reason.isNotEmpty ? reason : 'Component removed from inventory',
            timestamp: DateTime.now(),
          ),
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error deleting component: $e");
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Quick quantity adjustment (+/- delta) & record log
  Future<bool> adjustQuantity(
    String id,
    int delta, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final index = _components.indexWhere((c) => c.id == id);
      if (index == -1) return false;

      final current = _components[index];
      final currentQty = current.quantity ?? 0;
      final newQty = (currentQty + delta).clamp(0, 999999);
      final now = DateTime.now();

      final updated = current.copyWith(
        quantity: newQty,
        updatedAt: now,
      );

      _components[index] = updated;
      notifyListeners();

      await _collection.doc(id).update({
        'quantity': newQty,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Record Log
      await _recordLog(
        InventoryLog(
          componentId: id,
          componentName: current.name,
          actionType: InventoryActionType.qtyAdjusted,
          previousShelf: current.shelfNumber,
          newShelf: current.shelfNumber,
          previousQuantity: currentQty,
          newQuantity: newQty,
          quantityChange: delta,
          performedBy: performedBy,
          note: reason.isNotEmpty
              ? reason
              : (delta > 0 ? 'Stock replenished (+ $delta)' : 'Stock deducted ($delta)'),
          timestamp: now,
        ),
      );

      if (updated.isLowStock) {
        final alertId = _uuid.v4();
        await _firestore.collection('system_notifications').doc(alertId).set({
          'id': alertId,
          'title': 'Low Stock Alert: ${current.name}',
          'message': 'Component "${current.name}" on Shelf ${current.shelfNumber} has dropped to $newQty units (Threshold: ${current.minStockAlert ?? 5}).',
          'category': 'INVENTORY',
          'priority': newQty == 0 ? 'URGENT' : 'HIGH',
          'targetRole': 'ADMIN,ASSEMBLY_TEAM,OPERATIONS',
          'actionRoute': 'Inventory',
          'actionId': id,
          'isRead': false,
          'readBy': [],
          'createdAt': Timestamp.fromDate(now),
          'createdBy': performedBy,
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error adjusting quantity: $e");
      }
      return false;
    }
  }

  /// Set or remove quantity & record log
  Future<bool> setQuantity(
    String id,
    int? newQty, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final index = _components.indexWhere((c) => c.id == id);
      if (index == -1) return false;

      final current = _components[index];
      final prevQty = current.quantity;
      final now = DateTime.now();

      final updated = current.copyWith(
        quantity: newQty,
        clearQuantity: newQty == null,
        updatedAt: now,
      );

      _components[index] = updated;
      notifyListeners();

      await _collection.doc(id).update({
        'quantity': newQty,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Record Log
      await _recordLog(
        InventoryLog(
          componentId: id,
          componentName: current.name,
          actionType: InventoryActionType.qtySet,
          previousShelf: current.shelfNumber,
          newShelf: current.shelfNumber,
          previousQuantity: prevQty,
          newQuantity: newQty,
          quantityChange: (newQty != null && prevQty != null) ? (newQty - prevQty) : null,
          performedBy: performedBy,
          note: reason.isNotEmpty
              ? reason
              : (newQty == null ? 'Quantity set to untracked' : 'Quantity manually set to $newQty'),
          timestamp: now,
        ),
      );

      if (updated.isLowStock) {
        final alertId = _uuid.v4();
        await _firestore.collection('system_notifications').doc(alertId).set({
          'id': alertId,
          'title': 'Low Stock Alert: ${current.name}',
          'message': 'Component "${current.name}" on Shelf ${current.shelfNumber} has dropped to $newQty units (Threshold: ${current.minStockAlert ?? 5}).',
          'category': 'INVENTORY',
          'priority': (newQty ?? 0) == 0 ? 'URGENT' : 'HIGH',
          'targetRole': 'ADMIN,ASSEMBLY_TEAM,OPERATIONS',
          'actionRoute': 'Inventory',
          'actionId': id,
          'isRead': false,
          'readBy': [],
          'createdAt': Timestamp.fromDate(now),
          'createdBy': performedBy,
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error setting quantity: $e");
      }
      return false;
    }
  }

  /// Move component to a new shelf & record log
  Future<bool> updateShelf(
    String id,
    String newShelf, {
    String performedBy = 'Staff',
    String reason = '',
  }) async {
    try {
      final index = _components.indexWhere((c) => c.id == id);
      if (index == -1) return false;

      final current = _components[index];
      final prevShelf = current.shelfNumber;
      final now = DateTime.now();

      final updated = current.copyWith(
        shelfNumber: newShelf.trim(),
        updatedAt: now,
      );

      _components[index] = updated;
      notifyListeners();

      await _collection.doc(id).update({
        'shelfNumber': newShelf.trim(),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Record Log
      await _recordLog(
        InventoryLog(
          componentId: id,
          componentName: current.name,
          actionType: InventoryActionType.shelfMoved,
          previousShelf: prevShelf,
          newShelf: newShelf.trim(),
          previousQuantity: current.quantity,
          newQuantity: current.quantity,
          performedBy: performedBy,
          note: reason.isNotEmpty ? reason : 'Physical shelf location changed',
          timestamp: now,
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating shelf: $e");
      }
      return false;
    }
  }

  /// Import components from ProductOption list if not already in inventory & record log
  Future<int> importFromProducts(
    List<ProductOption> products, {
    String defaultShelf = 'Shelf A-01',
    String performedBy = 'Staff',
  }) async {
    int importedCount = 0;
    try {
      final existingNames = _components
          .map((c) => c.name.trim().toLowerCase())
          .toSet();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final p in products) {
        for (final c in p.components) {
          final normalizedName = c.componentName.trim().toLowerCase();
          if (normalizedName.isNotEmpty && !existingNames.contains(normalizedName)) {
            existingNames.add(normalizedName);
            final newId = _uuid.v4();
            final docRef = _collection.doc(newId);

            final newComp = InventoryComponent(
              id: newId,
              name: c.componentName.trim(),
              shelfNumber: defaultShelf,
              quantity: c.availableStock > 0 ? c.availableStock : null,
              category: 'Hardware',
              unit: 'pcs',
              description: 'Imported from product schema: ${p.name}',
              createdAt: now,
              updatedAt: now,
            );

            batch.set(docRef, newComp.toJson());
            importedCount++;
          }
        }
      }

      if (importedCount > 0) {
        await batch.commit();
        await fetchComponents();

        // Record Log
        await _recordLog(
          InventoryLog(
            componentId: 'batch-import',
            componentName: '$importedCount Components',
            actionType: InventoryActionType.imported,
            newShelf: defaultShelf,
            performedBy: performedBy,
            note: 'Batch imported $importedCount components from product catalog into $defaultShelf',
            timestamp: now,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error importing from products: $e");
      }
    }
    return importedCount;
  }

  // ═══════════════════════════════════════════════════════
  //  Aggregated Metrics & Helpers
  // ═══════════════════════════════════════════════════════

  List<String> get uniqueShelves {
    final shelves = _components
        .map((c) => c.shelfNumber.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    shelves.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return shelves;
  }

  List<String> get uniqueCategories {
    final cats = _components
        .map((c) => c.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cats;
  }

  int get totalComponents => _components.length;

  int get totalShelves => uniqueShelves.length;

  int get totalStockUnits {
    return _components.fold<int>(
      0,
      (acc, item) => acc + (item.quantity ?? 0),
    );
  }

  int get lowStockCount {
    return _components.where((c) => c.isLowStock || c.isOutOfStock).length;
  }

  int get untrackedCount {
    return _components.where((c) => c.quantity == null).length;
  }
}
