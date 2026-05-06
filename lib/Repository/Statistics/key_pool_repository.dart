import 'package:cloud_firestore/cloud_firestore.dart';

class KeyPoolRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add a batch of keys to a specific provider's pool
  static Future<void> importKeys(String provider, List<String> keys) async {
    final batch = _db.batch();
    for (var key in keys) {
      if (key.trim().isEmpty) continue;
      final docRef = _db.collection('key_pools').doc();
      batch.set(docRef, {
        'provider': provider.toLowerCase(),
        'apiKey': key.trim(),
        'status': 'unused',
        'assignedSchoolId': null,
        'assignedSchoolName': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Get counts of unused keys
  static Stream<Map<String, int>> getPoolStats() {
    return _db.collection('key_pools').snapshots().map((snap) {
      Map<String, int> stats = {'openrouter': 0, 'gemini': 0, 'grok': 0};
      for (var doc in snap.docs) {
        final provider = doc.get('provider') as String;
        final status = doc.get('status') as String;
        if (status == 'unused' && stats.containsKey(provider)) {
          stats[provider] = stats[provider]! + 1;
        }
      }
      return stats;
    });
  }

  /// Automatically assign 3 keys to a school
  static Future<Map<String, String?>> autoProvisionKeys(String schoolId, String schoolName) async {
    final providers = ['openrouter', 'gemini', 'grok'];
    Map<String, String?> assignedKeys = {};

    for (var provider in providers) {
      final snap = await _db.collection('key_pools')
          .where('provider', isEqualTo: provider)
          .where('status', isEqualTo: 'unused')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final key = doc.get('apiKey') as String;
        
        await doc.reference.update({
          'status': 'assigned',
          'assignedSchoolId': schoolId,
          'assignedSchoolName': schoolName,
          'assignedAt': FieldValue.serverTimestamp(),
        });
        
        assignedKeys[provider] = key;
      }
    }
    return assignedKeys;
  }

  /// Get AWS Config
  static Stream<Map<String, String>> getAwsConfig() {
    return _db.collection('system_configs').doc('aws').snapshots().map((snap) {
      if (!snap.exists) return {};
      return Map<String, String>.from(snap.data()!);
    });
  }

  /// Save AWS Config
  static Future<void> saveAwsConfig(Map<String, String> config) async {
    await _db.collection('system_configs').doc('aws').set(config);
  }
}
