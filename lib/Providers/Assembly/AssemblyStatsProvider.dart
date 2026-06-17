import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssemblyStatsProvider extends ChangeNotifier {
  int totalManufactured = 0;
  int defectiveBots = 0;
  int readyToDispatch = 0;
  bool isLoading = true;

  AssemblyStatsProvider() {
    _initListener();
  }

  void _initListener() {
    FirebaseFirestore.instance
        .collection('system_configs')
        .doc('assembly_stats')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        totalManufactured = data['totalManufactured'] ?? 0;
        defectiveBots = data['defectiveBots'] ?? 0;
        readyToDispatch = data['readyToDispatch'] ?? 0;
      } else {
        // Create the document if it doesn't exist
        updateStats(
          manufactured: 0,
          defective: 0,
          ready: 0,
        );
      }
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to assembly stats: $e");
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStats({
    required int manufactured,
    required int defective,
    required int ready,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('system_configs')
          .doc('assembly_stats')
          .set({
        'totalManufactured': manufactured,
        'defectiveBots': defective,
        'readyToDispatch': ready,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to update assembly stats: $e");
      rethrow;
    }
  }
}
