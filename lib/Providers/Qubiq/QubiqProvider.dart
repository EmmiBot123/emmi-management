import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Services/Auth_service.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../Resources/api_endpoints.dart';


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

      // 1. Filter strictly for confirmed payments
      final filteredList = visits
          .where((v) => v.payment.paymentConfirmed == true)
          .toList();

      // 2. Auto-generate school codes for those that don't have one (or have a duplicate '3991')
      final existingCodes = visits
          .where((v) => v.schoolCode != null && v.schoolCode!.isNotEmpty)
          .map((v) => v.schoolCode!)
          .toSet();

      final random = Random();

      for (var i = 0; i < filteredList.length; i++) {
        var v = filteredList[i];
        
        bool needsRegeneration = (v.schoolCode == null || v.schoolCode!.isEmpty);
        
        // Specific fix: If it has '3991' but isn't 'abcd', regenerate it
        if (v.schoolCode == '3991' && v.schoolProfile.name.toLowerCase() != 'abcd') {
          needsRegeneration = true;
        }

        if (needsRegeneration) {
          String newCode;
          if (v.schoolProfile.name.toLowerCase() == 'abcd') {
            newCode = '3991';
          } else {
            // Generate a unique 4-digit code
            int codeInt;
            do {
              codeInt = 1000 + random.nextInt(9000);
              newCode = codeInt.toString();
            } while (existingCodes.contains(newCode));
          }
          
          v.schoolCode = newCode;
          existingCodes.add(newCode); // Mark as taken
          // Persist the generated code
          await _repository.updateVisit(v);

          // 🆕 Sync to Qubiq Firebase
          await syncSchoolToQubiq(v.schoolCode!, v.schoolProfile.name);
        } else {
          // Even if code exists, ensuring it's synced (idempotent)
          if (v.schoolCode != null && v.schoolCode!.isNotEmpty) {
            await syncSchoolToQubiq(v.schoolCode!, v.schoolProfile.name);
          }
        }
      }

      confirmedSchools = filteredList;

      // 🔍 Self-Healing: Check Qubiq Project for missing admins
      await _discoverMissingAdmins();

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

      // Generate or retrieve the 4-digit school code
      String schoolCode = visit.schoolCode ?? "";
      if (schoolCode.isEmpty || (schoolCode == '3991' && visit.schoolProfile.name.toLowerCase() != 'abcd')) {
        if (visit.schoolProfile.name.toLowerCase() == 'abcd') {
          schoolCode = '3991';
        } else {
          // Generate a random 4-digit code (simple fallback if not pre-generated)
          schoolCode = (1000 + Random().nextInt(9000)).toString();
        }
      }

      // 1. Create Auth User & Firestore Doc
      final String uid = await _authService.createSchoolAdmin(
        email: email,
        password: password,
        name: name,
        phone: phone,
        schoolId: schoolCode, // Pass the 4-digit code!
        apiKeys: apiKeys.toJson().cast<String, String>(),
      );

      // 2. Update SchoolVisit with adminId, name, and the new schoolCode
      final updatedVisit = visit.copyWith(); // Clone
      updatedVisit.adminId = uid;
      updatedVisit.adminName = name;
      updatedVisit.schoolCode = schoolCode;

      await _repository.updateVisit(updatedVisit);

      // 3. Update local list
      final index = confirmedSchools.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        confirmedSchools[index] = updatedVisit;
      }

      // 4. Sync initial keys to Node server using the 4-digit schoolCode
      try {
        await _syncKeysToNodeServer(schoolCode, apiKeys);
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

  /// 🛠️ Manually mark a school as "Admin Created"
  Future<bool> manualMarkAsAdminCreated(SchoolVisit visit, String? customAdminId) async {
    try {
      isLoading = true;
      notifyListeners();

      if (visit.id == null) return false;

      final adminId = customAdminId ?? "MANUAL_ADMIN_${visit.schoolCode ?? 'UNKNOWN'}";
      
      await FirebaseFirestore.instance
          .collection('school_visits')
          .doc(visit.id)
          .set({
        'adminId': adminId,
        'adminName': "Manually Verified",
      }, SetOptions(merge: true));

      visit.adminId = adminId;
      visit.adminName = "Manually Verified";
      
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = "Manual mark failed: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 📧 Update the admin name/email locally
  Future<bool> updateAdminName(SchoolVisit visit, String newName) async {
    try {
       if (visit.id == null) return false;
       
       await FirebaseFirestore.instance
          .collection('school_visits')
          .doc(visit.id)
          .set({
        'adminName': newName,
      }, SetOptions(merge: true));
      visit.adminName = newName;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🛰️ Generate a unique setup link for a school admin
  Future<String?> generateSetupLink({
    required SchoolVisit visit,
    required String email,
    required UserApiKeys apiKeys,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Generate a unique token
      final String token = _generateRandomToken(32);

      // 2. Prepare data for 'pending_setups'
      final setupData = {
        'token': token,
        'email': email.trim(),
        'schoolId': visit.schoolCode ?? (1000 + Random().nextInt(9000)).toString(),
        'schoolName': visit.schoolProfile.name,
        'apiKeys': apiKeys.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      };

      // 3. Store in Firestore (root collection)
      await FirebaseFirestore.instance.collection('pending_setups').doc(token).set(setupData);

      // 4. Mark the school as "Setup In Progress" immediately
      if (visit.id != null) {
        await FirebaseFirestore.instance
            .collection('school_visits')
            .doc(visit.id)
            .update({
          'adminId': 'PENDING_SETUP',
          'adminName': email,
          'setupToken': token, // Store token for pre-filling later
        });

        // Update local state for immediate UI feedback
        visit.adminId = 'PENDING_SETUP';
        visit.adminName = email;
        notifyListeners();
      }

      // 5. Construct the link
      const String baseUrl = "https://qubiqai.netlify.app";
      final String setupLink = "$baseUrl/#/login?setup=true&token=$token&email=${Uri.encodeComponent(email)}";

      // 6. AUTO-SEND EMAIL (EmailJS)
      await _sendSetupEmail(
        toEmail: email.trim(),
        schoolName: visit.schoolProfile.name,
        setupLink: setupLink,
      );

      return setupLink;
    } catch (e) {
      errorMessage = "Failed to generate link: $e";
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _generateRandomToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _sendSetupEmail({
    required String toEmail,
    required String schoolName,
    required String setupLink,
  }) async {
    const String serviceId = "service_bfu9is8";
    const String templateId = "template_h9apqoj"; 
    const String publicKey = "25m02sQQ9YzU3GnLY";

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': toEmail, // Matches {{email}} in screenshot
            'name': schoolName, // Matches {{name}} in screenshot
            'setup_link': setupLink,
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Setup Email sent successfully to $toEmail");
      } else {
        debugPrint("❌ Failed to send setup email: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error sending setup email: $e");
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

      // Sync to Node server using the 4-digit schoolCode
      try {
        final school = confirmedSchools.firstWhere((s) => s.adminId == adminId);
        final String schoolCode =
            school.schoolCode != null && school.schoolCode!.isNotEmpty
                ? school.schoolCode!
                : school.schoolProfile.name.toLowerCase().contains('abcd')
                    ? '3991'
                    : school.id ?? 'unknown';

        await _syncKeysToNodeServer(schoolCode, keys);
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

  /// 🔄 Sync School Metadata to Qubiq App Firebase Project
  Future<void> syncSchoolToQubiq(String schoolId, String schoolName) async {
    try {
      final url = Uri.parse(ApiEndpoints.syncSchool);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c",
        },
        body: jsonEncode({
          "schoolId": schoolId,
          "schoolName": schoolName,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Sync Success: $schoolName ($schoolId)");
      } else {
        debugPrint(
            "❌ Sync Failed for $schoolName: ${response.statusCode} - ${response.body}");
        debugPrint("URL used: ${ApiEndpoints.syncSchool}");
      }
    } catch (e) {
      debugPrint("🔥 Sync Exceptional Error for $schoolName: $e");
    }
  }

  // 🚀 DISCOVERY SYNC: Consolidated Server-Side Discovery & Sync (Ultimate Proxy Fix)
  Future<void> _discoverMissingAdmins() async {
    try {
      for (var school in confirmedSchools) {
        if (school.adminId == null || school.adminId!.isEmpty) {
          if (school.schoolCode == null || school.schoolCode!.isEmpty) continue;
          if (school.id == null) continue; // Visit Firestore Document ID

          debugPrint("🔍 Discovery Sync: Checking Qubiq for Admin of school ${school.schoolCode}");
          
          final response = await http.post(
            Uri.parse(ApiEndpoints.discoverySync),
            headers: {
              "Content-Type": "application/json",
              "x-api-key": "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c",
            },
            body: jsonEncode({
              "schoolCode": school.schoolCode,
              "visitDocId": school.id,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            school.adminId = data['adminId'];
            school.adminName = data['adminName'] ?? 'Admin';

            debugPrint("✅ Discovery Sync: Linked Admin ${school.adminName} for ${school.schoolCode}");
            notifyListeners();
          } else {
            debugPrint("ℹ️ Discovery Sync: No admin found or error ${response.statusCode} for school ${school.schoolCode}");
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Discovery Sync failed: $e");
    }
  }
}
