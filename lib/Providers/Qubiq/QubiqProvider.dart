import 'package:flutter/material.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Services/Auth_service.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QubiqProvider extends ChangeNotifier {
  final SchoolVisitRepository _repository = SchoolVisitRepository();
  final AuthService _authService = AuthService();

  List<SchoolVisit> confirmedSchools = [];
  bool isLoading = false;
  String? errorMessage;

  // Revised fetch method - fetches ALL visits to include those from other users
  Future<void> loadConfirmedSchools(String userId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Use getPaymentVisits to fetch ALL visits as the Super Admin/Qubiq Manager
      // needs to see schools created by other users (sales reps).
      final visits = await _repository.getPaymentVisits();

      confirmedSchools =
          visits.where((v) => v.visitDetails.status == "CLOSED_WON").toList();

      // Sort Newest -> Oldest
      confirmedSchools.sort((a, b) {
        final DateTime dateA =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      errorMessage = e.toString();
      confirmedSchools = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAdminForSchool({
    required SchoolVisit visit,
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserApiKeys apiKeys,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Create Auth User & Firestore Doc
      final String uid = await _authService.createSchoolAdmin(
        email: email,
        password: password,
        name: name,
        phone: phone,
        apiKeys: apiKeys.toJson().cast<String, String>(),
      );

      // 2. Update SchoolVisit with adminId and name
      final updatedVisit = visit.copyWith(); // Clone
      updatedVisit.adminId = uid;
      updatedVisit.adminName = name;

      await _repository.updateVisit(updatedVisit);

      // 3. Update local list
      final index = confirmedSchools.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        confirmedSchools[index] = updatedVisit;
      }

      // 4. Sync initial keys to Node server
      try {
        if (visit.id != null && visit.id!.isNotEmpty) {
          await _syncKeysToNodeServer(visit.id!, apiKeys);
        }
      } catch (e) {
        print('Could not sync keys on admin creation: $e');
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<UserApiKeys?> getSchoolApiKeys(String adminId) async {
    try {
      final data = await _authService.getApiKeys(adminId);
      return UserApiKeys.fromJson(data);
    } catch (e) {
      print("Error fetching keys: $e");
      return null;
    }
  }

  Future<bool> updateSchoolApiKeys(String adminId, UserApiKeys keys) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.updateApiKeys(adminId, keys.toJson());

      // Sync to Node server
      try {
        final school = confirmedSchools.firstWhere((s) => s.adminId == adminId);
        if (school.id != null && school.id!.isNotEmpty) {
          await _syncKeysToNodeServer(school.id!, keys);
        }
      } catch (e) {
        print("Could not find school for admin $adminId to sync keys: $e");
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Remove admin from school (reset)
  Future<bool> removeAdminForSchool(SchoolVisit visit) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Update SchoolVisit (clear adminId and adminName)
      final updatedVisit = visit.copyWith();
      updatedVisit.adminId = null;
      updatedVisit.adminName = null;

      await _repository.updateVisit(updatedVisit);

      // 2. Update local list
      final index = confirmedSchools.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        confirmedSchools[index] = updatedVisit;
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Search for any school by name (fetches all visits first if needed)
  Future<List<SchoolVisit>> searchSchools(String query) async {
    if (query.isEmpty) return [];

    // We might need to fetch ALL visits to search effectively if the API doesn't support search.
    // Assuming getPaymentVisits returns a broad list or we reuse existing logic.
    // For now, let's try fetching "Payment Visits" which seems to be the "All Visits" equivalent for Admin/Accounts
    // based on repository code inspection (it hits ApiEndpoints.createVisit with GET).

    try {
      final allVisits = await _repository.getPaymentVisits();

      final lowerQuery = query.toLowerCase();
      return allVisits.where((v) {
        return v.schoolProfile.name.toLowerCase().contains(lowerQuery) ||
            v.schoolProfile.city.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }

  /// Manually add a school to the configuration list
  void addManualSchool(SchoolVisit visit) {
    // Check if already exists
    final exists = confirmedSchools.any((v) => v.id == visit.id);
    if (!exists) {
      confirmedSchools.add(visit);
      notifyListeners();
    }
  }

  Future<void> _syncKeysToNodeServer(String schoolId, UserApiKeys keys) async {
    const url = 'https://edu-ai-backend-vl7s.onrender.com/admin/school-keys';
    const apiKey =
        'b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'schoolId': schoolId,
          'keys': keys.toNodeJson(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
            'Failed to sync keys to Node server: ${response.statusCode} ${response.body}');
      } else {
        print('Successfully synced keys to Node server.');
      }
    } catch (e) {
      print('Error syncing keys to Node server: $e');
    }
  }
}
