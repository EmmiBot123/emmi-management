import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Model/Bill.dart';

class BillProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Bill> _myBills = [];
  List<Bill> _allBills = [];
  bool _isLoading = false;

  List<Bill> get myBills => _myBills;
  List<Bill> get allBills => _allBills;
  bool get isLoading => _isLoading;

  // Add a new bill
  Future<void> addBill(Bill bill) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('bills').add(bill.toMap());

      // Refresh my list
      await loadMyBills(bill.userId);
    } catch (e) {
      print("Error adding bill: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load bills for a specific user (Marketing view)
  Future<void> loadMyBills(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('bills')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _myBills =
          snapshot.docs.map((doc) => Bill.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Error loading my bills: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load ALL bills (Accounts/Admin view)
  Future<void> loadAllBills() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('bills')
          .orderBy('createdAt', descending: true)
          .get();

      _allBills =
          snapshot.docs.map((doc) => Bill.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Error loading all bills: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update bill status (Approve/Reject)
  Future<void> updateBillStatus(String billId, String newStatus) async {
    try {
      await _firestore
          .collection('bills')
          .doc(billId)
          .update({'status': newStatus});

      // Update local lists
      final index = _allBills.indexWhere((b) => b.id == billId);
      if (index != -1) {
        _allBills[index].status = newStatus;
      }

      notifyListeners();
    } catch (e) {
      print("Error updating bill status: $e");
      rethrow;
    }
  }
}
