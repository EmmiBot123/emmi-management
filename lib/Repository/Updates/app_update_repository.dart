import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../Model/Updates/app_update_model.dart';

class AppUpdateRepository {
  static const String collectionName = 'app_updates';
  static FirebaseFirestore? _qubiqFirestore;
  static bool _isAuthenticated = false;

  /// Get the Firestore instance for Qubiq student app Firebase project (qubiqai-db7a3).
  static Future<FirebaseFirestore> _getQubiqFirestore() async {
    if (_qubiqFirestore != null && _isAuthenticated) return _qubiqFirestore!;

    const String appName = 'QubiqAppUpdates';
    FirebaseApp app;
    try {
      app = Firebase.app(appName);
    } catch (e) {
      app = await Firebase.initializeApp(
        name: appName,
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDo18sjfSXv6jfyAEytR301TbiQwjVJ7lQ',
          appId: '1:36391250694:web:e9c9a4e7ce76f5e8f98c87',
          messagingSenderId: '36391250694',
          projectId: 'qubiqai-db7a3',
          authDomain: 'qubiqai-db7a3.firebaseapp.com',
          storageBucket: 'qubiqai-db7a3.firebasestorage.app',
        ),
      );
    }

    if (!_isAuthenticated) {
      try {
        final auth = FirebaseAuth.instanceFor(app: app);
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
          debugPrint('🔓 Anonymous sign-in to QubiqApp for app_updates');
        }
        _isAuthenticated = true;
      } catch (e) {
        debugPrint('⚠️ Anonymous auth failed for QubiqApp app_updates: $e');
      }
    }

    _qubiqFirestore = FirebaseFirestore.instanceFor(app: app);
    return _qubiqFirestore!;
  }

  /// Create or Publish a new App Update Broadcast across both databases
  Future<String> createUpdate(AppUpdateModel update) async {
    try {
      // 1. Sync to Qubiq App Firestore (so all client apps see it)
      final qubiqDb = await _getQubiqFirestore();
      final docRef = qubiqDb.collection(collectionName).doc();
      final updateWithId = update.copyWith(id: docRef.id);
      await docRef.set(updateWithId.toMap());

      // 2. Also write to Primary Management Firestore
      try {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(docRef.id)
            .set(updateWithId.toMap());
      } catch (e) {
        debugPrint('Note: primary db write optional fallback: $e');
      }

      debugPrint('✅ Broadcast created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating update broadcast: $e');
      rethrow;
    }
  }

  /// Fetch all updates (ordered newest first)
  Future<List<AppUpdateModel>> getAllUpdates() async {
    try {
      final qubiqDb = await _getQubiqFirestore();
      final snapshot = await qubiqDb
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppUpdateModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching from Qubiq Firebase, falling back to local: $e');
      try {
        final localSnap = await FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('createdAt', descending: true)
            .get();
        return localSnap.docs
            .map((doc) => AppUpdateModel.fromFirestore(doc))
            .toList();
      } catch (err) {
        debugPrint('❌ Error fetching updates from local: $err');
        return [];
      }
    }
  }

  /// Update an existing broadcast
  Future<bool> updateNotification(AppUpdateModel update) async {
    try {
      final qubiqDb = await _getQubiqFirestore();
      await qubiqDb
          .collection(collectionName)
          .doc(update.id)
          .set(update.toMap(), SetOptions(merge: true));

      try {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(update.id)
            .set(update.toMap(), SetOptions(merge: true));
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('❌ Error updating notification: $e');
      return false;
    }
  }

  /// Toggle Active status
  Future<bool> toggleActiveStatus(String updateId, bool newStatus) async {
    try {
      final qubiqDb = await _getQubiqFirestore();
      await qubiqDb.collection(collectionName).doc(updateId).update({
        'isActive': newStatus,
      });

      try {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(updateId)
            .update({'isActive': newStatus});
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('❌ Error toggling active status: $e');
      return false;
    }
  }

  /// Delete an update broadcast
  Future<bool> deleteUpdate(String updateId) async {
    try {
      final qubiqDb = await _getQubiqFirestore();
      await qubiqDb.collection(collectionName).doc(updateId).delete();

      try {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(updateId)
            .delete();
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting update: $e');
      return false;
    }
  }

  /// Real-time stream of updates
  Stream<List<AppUpdateModel>> streamUpdates() async* {
    final qubiqDb = await _getQubiqFirestore();
    yield* qubiqDb
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppUpdateModel.fromFirestore(doc))
            .toList());
  }
}
