import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/Updates/app_update_model.dart';

/// Client-side service for checking and listening to application updates,
/// announcements, and critical app alerts across the QubiQ / EMMI ecosystem.
class UpdateNotificationService {
  static const String collectionName = 'app_updates';
  static const String seenUpdatesPrefKey = 'seen_update_ids_v1';

  final FirebaseFirestore _firestore;

  UpdateNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper to check if an update is active and targeted for the user
  static bool isUpdateActiveAndTargeted(
    AppUpdateModel update,
    String userRole,
    String? schoolCode,
  ) {
    if (!update.isActive) return false;

    if (update.expiresAt != null && update.expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    final normalizedUserRole = userRole.toLowerCase().trim();
    final roleMatches = update.targetRoles.isEmpty ||
        update.targetRoles.any((r) {
          final role = r.toLowerCase().trim();
          return role == 'all' ||
              role == normalizedUserRole ||
              (normalizedUserRole == 'student' && (role == 'student' || role == 'students')) ||
              (normalizedUserRole == 'teacher' && (role == 'teacher' || role == 'teachers')) ||
              (normalizedUserRole == 'admin' && (role == 'admin' || role == 'admins'));
        });

    final schoolMatches = update.targetSchools == null ||
        update.targetSchools!.isEmpty ||
        (schoolCode != null && update.targetSchools!.contains(schoolCode));

    return roleMatches && schoolMatches;
  }

  /// Fetch all active updates targeted for the current user's role and school.
  /// (Does not use composite Firestore indexes to guarantee 100% reliable execution).
  Future<List<AppUpdateModel>> getActiveUpdates({
    String userRole = 'all',
    String? schoolCode,
  }) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();

      final allUpdates = snapshot.docs
          .map((doc) => AppUpdateModel.fromFirestore(doc))
          .toList();

      // Sort newest first in Dart
      allUpdates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final filtered = allUpdates
          .where((u) => isUpdateActiveAndTargeted(u, userRole, schoolCode))
          .toList();

      debugPrint('📢 UpdateNotificationService: ${allUpdates.length} total in db, ${filtered.length} active matching role "$userRole"');
      return filtered;
    } catch (e) {
      debugPrint('⚠️ Error fetching active updates: $e');
      return [];
    }
  }

  /// Check if a specific target app has an active critical update.
  /// Example: `checkCriticalAlertForApp('Emmi Lite')` or `checkCriticalAlertForApp('laser')`
  Future<AppUpdateModel?> checkCriticalAlertForApp(
    String appKey, {
    String userRole = 'all',
    String? schoolCode,
  }) async {
    try {
      final activeUpdates = await getActiveUpdates(
        userRole: userRole,
        schoolCode: schoolCode,
      );

      final normalizedAppKey = appKey.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

      for (final update in activeUpdates) {
        if (!update.isCritical) continue;

        final target = update.targetApp.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

        // Match specific app key or global critical alert
        if (target == 'all' ||
            target == normalizedAppKey ||
            normalizedAppKey.contains(target) ||
            target.contains(normalizedAppKey) ||
            ((normalizedAppKey.contains('robot') || normalizedAppKey.contains('emmi')) &&
                (target == 'emmi_lite' || target == 'emmi_core' || target == 'robot')) ||
            (normalizedAppKey.contains('laser') && target.contains('laser')) ||
            (normalizedAppKey.contains('studio') && target.contains('studio')) ||
            (normalizedAppKey.contains('python') && target.contains('python'))) {
          debugPrint('🚨 Critical Alert found for app "$appKey": ${update.title}');
          return update;
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error checking critical alert for app "$appKey": $e');
      return null;
    }
  }

  /// Get list of unseen updates for "What's New" modal on dashboard login
  Future<List<AppUpdateModel>> getUnseenUpdates({
    String userRole = 'all',
    String? schoolCode,
  }) async {
    try {
      final activeUpdates = await getActiveUpdates(
        userRole: userRole,
        schoolCode: schoolCode,
      );
      final prefs = await SharedPreferences.getInstance();
      final seenIds = prefs.getStringList(seenUpdatesPrefKey) ?? [];

      return activeUpdates.where((u) => u.id.isNotEmpty && !seenIds.contains(u.id)).toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching unseen updates: $e');
      return [];
    }
  }

  /// Mark specific updates as seen
  Future<void> markUpdatesAsSeen(List<String> updateIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenIds = (prefs.getStringList(seenUpdatesPrefKey) ?? []).toSet();
      seenIds.addAll(updateIds.where((id) => id.isNotEmpty));
      await prefs.setStringList(seenUpdatesPrefKey, seenIds.toList());
      debugPrint('✅ Marked ${updateIds.length} updates as seen');
    } catch (e) {
      debugPrint('⚠️ Error marking updates as seen: $e');
    }
  }

  /// Real-time stream of active updates
  Stream<List<AppUpdateModel>> streamActiveUpdates({
    String userRole = 'all',
    String? schoolCode,
  }) {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppUpdateModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list
          .where((u) => isUpdateActiveAndTargeted(u, userRole, schoolCode))
          .toList();
    });
  }
}
