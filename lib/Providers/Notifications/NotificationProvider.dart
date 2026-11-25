import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../Model/Notifications/SystemNotificationModel.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<SystemNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<SystemNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('system_notifications');

  NotificationProvider() {
    initRealtimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void initRealtimeListener() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _collection
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return SystemNotificationModel.fromJson(data, doc.id);
        }).toList();

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to system_notifications: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  List<SystemNotificationModel> getNotificationsForUser(
    String userId,
    String userRole, {
    String? categoryFilter,
  }) {
    return _notifications.where((n) {
      if (!n.isRelevantToRole(userRole)) return false;
      if (categoryFilter != null &&
          categoryFilter != 'ALL' &&
          n.category.toUpperCase() != categoryFilter.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  int getUnreadCount(String userId, String userRole) {
    return _notifications.where((n) {
      return n.isRelevantToRole(userRole) && !n.isReadByUser(userId);
    }).length;
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      // Optimistic local update
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final current = _notifications[index];
        final updatedReadBy = List<String>.from(current.readBy);
        if (!updatedReadBy.contains(userId)) {
          updatedReadBy.add(userId);
        }
        _notifications[index] = current.copyWith(readBy: updatedReadBy);
        notifyListeners();
      }

      await _collection.doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId, String userRole) async {
    try {
      final relevant = getNotificationsForUser(userId, userRole)
          .where((n) => !n.isReadByUser(userId))
          .toList();

      if (relevant.isEmpty) return;

      // Optimistic local update
      for (final n in relevant) {
        final index = _notifications.indexWhere((item) => item.id == n.id);
        if (index != -1) {
          final updatedReadBy = List<String>.from(_notifications[index].readBy);
          if (!updatedReadBy.contains(userId)) {
            updatedReadBy.add(userId);
          }
          _notifications[index] = _notifications[index].copyWith(readBy: updatedReadBy);
        }
      }
      notifyListeners();

      final batch = _firestore.batch();
      for (final n in relevant) {
        final docRef = _collection.doc(n.id);
        batch.update(docRef, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<bool> sendNotification({
    required String title,
    required String message,
    String category = 'GENERAL',
    String priority = 'MEDIUM',
    String targetRole = 'ALL',
    String? actionRoute,
    String? actionId,
    String? createdBy,
  }) async {
    try {
      final id = _uuid.v4();
      final model = SystemNotificationModel(
        id: id,
        title: title,
        message: message,
        category: category,
        priority: priority,
        targetRole: targetRole,
        actionRoute: actionRoute,
        actionId: actionId,
        isRead: false,
        readBy: const [],
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _collection.doc(id).set(model.toJson());
      return true;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();

      await _collection.doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  Future<void> triggerLowStockAlert({
    required String componentName,
    required int currentQuantity,
    required int threshold,
    required String shelfNumber,
  }) async {
    try {
      // Prevent flood: check if recent alert in last 2 hours for this component
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final exists = _notifications.any((n) =>
          n.category == 'INVENTORY' &&
          n.title.contains(componentName) &&
          n.createdAt.isAfter(twoHoursAgo));

      if (exists) return;

      await sendNotification(
        title: 'Low Stock Alert: $componentName',
        message:
            'Part "$componentName" on Shelf $shelfNumber is down to $currentQuantity units (Min Threshold: $threshold).',
        category: 'INVENTORY',
        priority: currentQuantity == 0 ? 'URGENT' : 'HIGH',
        targetRole: 'ADMIN,ASSEMBLY_TEAM,OPERATIONS',
        actionRoute: 'Inventory',
        createdBy: 'System Auto-Monitor',
      );
    } catch (e) {
      debugPrint('Error triggering low stock alert: $e');
    }
  }
}
