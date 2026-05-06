import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Repository for fetching login location data from the Qubiq student app's
/// Firebase project (qubiqai-db7a3). Used to display user login locations
/// on the India map in the admin dashboard.
class LoginMapRepository {
  static FirebaseFirestore? _qubiqFirestore;
  static bool _isAuthenticated = false;

  /// Initialize the secondary Qubiq Firebase app and sign in anonymously
  /// so Firestore rules (which require auth) are satisfied.
  static Future<FirebaseFirestore> _getQubiqFirestore() async {
    if (_qubiqFirestore != null && _isAuthenticated) return _qubiqFirestore!;

    const String appName = 'QubiqApp';
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

    // Sign in anonymously to satisfy Firestore rules (request.auth != null)
    if (!_isAuthenticated) {
      try {
        final auth = FirebaseAuth.instanceFor(app: app);
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
          debugPrint('🔓 Anonymous sign-in to QubiqApp for login_logs read');
        }
        _isAuthenticated = true;
      } catch (e) {
        debugPrint('⚠️ Anonymous auth failed for QubiqApp: $e');
      }
    }

    _qubiqFirestore = FirebaseFirestore.instanceFor(app: app);
    return _qubiqFirestore!;
  }

  /// Fetch recent login locations for the map.
  /// Returns list of login entries with lat, lng, loginType, city, etc.
  /// [hours] — how many hours back to look (default: 168 = 7 days)
  static Future<List<Map<String, dynamic>>> getRecentLogins({
    int hours = 168,
  }) async {
    try {
      final firestore = await _getQubiqFirestore();
      final cutoff = DateTime.now().subtract(Duration(hours: hours));

      final snap = await firestore
          .collection('login_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Unknown',
          'userRole': data['userRole'] ?? 'student',
          'schoolId': data['schoolId'] ?? '',
          'loginMethod': data['loginMethod'] ?? 'unknown',
          'loginType': data['loginType'] ?? 'unknown',
          'ip': data['ip'] ?? 'unknown',
          'city': data['city'] ?? 'unknown',
          'region': data['region'] ?? 'unknown',
          'lat': (data['lat'] is num) ? (data['lat'] as num).toDouble() : 0.0,
          'lng': (data['lng'] is num) ? (data['lng'] as num).toDouble() : 0.0,
          'isp': data['isp'] ?? '',
          'timestamp': data['timestamp'],
          'sessionActive': data['sessionActive'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching login locations: $e');
      return [];
    }
  }

  /// Get aggregated login stats by type (school vs home)
  static Future<Map<String, int>> getLoginTypeCounts() async {
    try {
      final logins = await getRecentLogins(hours: 720); // Last 30 days
      int schoolLogins = 0;
      int homeLogins = 0;

      for (final login in logins) {
        if (login['loginType'] == 'school') {
          schoolLogins++;
        } else {
          homeLogins++;
        }
      }

      return {
        'schoolLogins': schoolLogins,
        'homeLogins': homeLogins,
        'total': schoolLogins + homeLogins,
      };
    } catch (e) {
      debugPrint('Error getting login type counts: $e');
      return {'schoolLogins': 0, 'homeLogins': 0, 'total': 0};
    }
  }
}
