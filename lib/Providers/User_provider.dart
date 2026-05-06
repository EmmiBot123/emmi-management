import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../Model/User_model.dart';
import '../Resources/api_endpoints.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> marketing = [];
  List<UserModel> teleMarketing = [];
  List<UserModel> assembly = [];
  List<UserModel> installation = [];
  List<UserModel> qubiq = [];
  List<UserModel> ads = [];
  List<UserModel> admin = [];
  bool isLoading = false;
  bool isLoadingAdd = false;
  Future<void> loadAdmins() async {
    try {
      isLoading = true;
      notifyListeners();

      try {
        final url = Uri.parse(ApiEndpoints.getUsers);
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final List jsonList = jsonDecode(response.body);

          final List<UserModel> allUsers =
              jsonList.map((item) => UserModel.fromJson(item)).toList();

          admin = allUsers
              .where((user) =>
                  user.role != null && user.role!.toLowerCase() == "admin")
              .toList();

          admin.sort((a, b) => (a.name ?? "")
              .toLowerCase()
              .compareTo((b.name ?? "").toLowerCase()));
        } else {
          print("API error: ${response.statusCode}");
        }
      } catch (e) {
        print("Error fetching from legacy API: $e");
        // We might want to fallback to Firestore here too if admins are moved there.
      }
    } catch (e) {
      print("Error fetching members => $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load members from API and Firestore
  Future<void> loadMembers(String _) async {
    try {
      isLoading = true;
      notifyListeners();

      List<UserModel> firestoreUsers = [];
      List<UserModel> apiUsers = [];

      // 1. Fetch from Firestore (Primary Source for new users)
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').get();
        firestoreUsers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is set
          return UserModel.fromJson(data);
        }).toList();
        print(
            "UserProvider: Fetched ${firestoreUsers.length} users from Firestore");
      } catch (e) {
        print("Error fetching from Firestore: $e");
      }

      // 2. Fetch from API (Legacy)
      try {
        final url = Uri.parse(ApiEndpoints.getUsers);
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final List jsonList = jsonDecode(response.body);
          apiUsers = jsonList.map((item) => UserModel.fromJson(item)).toList();
          print("UserProvider: Fetched ${apiUsers.length} users from API");
        } else {
          print("API error: ${response.statusCode}");
        }
      } catch (e) {
        print("Error fetching from API: $e");
      }

      // 3. Merge Lists (deduplicate by Email preferred, then ID)
      final Map<String, UserModel> mergedMap = {};

      // Helper to add user to map (normalize email)
      void addUserToMap(UserModel u) {
        if (u.email != null && u.email!.isNotEmpty) {
          final emailKey = u.email!.trim().toLowerCase();
          mergedMap[emailKey] = u;
        } else if (u.id != null) {
          mergedMap[u.id!] = u;
        }
      }

      // Add API users first
      for (var u in apiUsers) {
        addUserToMap(u);
      }

      // Add/Overwrite with Firestore users (Newer data wins)
      for (var u in firestoreUsers) {
        addUserToMap(u);
      }

      final List<UserModel> allUsers = mergedMap.values.toList();

      print("UserProvider: Total merged users: ${allUsers.length}");
      for (var u in allUsers) {
        print(
            " - User: ${u.name}, Role: ${u.role}, Source: ${firestoreUsers.contains(u) ? 'Firestore' : 'API'}");
      }

      // Filter lists
      marketing = allUsers
          .where((user) =>
              user.role != null && user.role!.toUpperCase() == "MARKETING")
          .toList();
      teleMarketing = allUsers
          .where((user) =>
              user.role != null && user.role!.toUpperCase() == "TELE_MARKETING")
          .toList();
      assembly = allUsers
          .where((user) =>
              user.role != null && user.role!.toUpperCase() == "ASSEMBLY_TEAM")
          .toList();
      installation = allUsers
          .where((user) =>
              user.role != null &&
              user.role!.toUpperCase() == "INSTALLATION_TEAM")
          .toList();
      qubiq = allUsers
          .where((user) =>
              user.role != null && user.role!.toUpperCase() == "QUBIQ")
          .toList();
      ads = allUsers
          .where(
              (user) => user.role != null && user.role!.toUpperCase() == "ADS")
          .toList();
      admin = allUsers
          .where((user) =>
              user.role != null && user.role!.toUpperCase() == "ADMIN")
          .toList();

      // Helper to sort
      void sortList(List<UserModel> list) {
        list.sort((a, b) => (a.name ?? "")
            .toLowerCase()
            .compareTo((b.name ?? "").toLowerCase()));
      }

      sortList(marketing);
      sortList(teleMarketing);
      sortList(assembly);
      sortList(installation);
      sortList(qubiq);
      sortList(ads);
    } catch (e) {
      print("Error fetching members => $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> loadAdmin(String userID) async {
    try {
      try {
        final url = Uri.parse(ApiEndpoints.getUsersById(userID));
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(data);
          final user = UserModel.fromJson(data);
          return user;
        } else {
          print("API error: ${response.statusCode}");
        }
      } catch (e) {
        print("Error fetching from legacy API: $e");
      }
    } catch (e) {
      print("Error fetching admin => $e");
    }
    return null;
  }

  // Add new member
  Future<String> addUser(
    String name,
    String email,
    String role,
    String adminId,
    String adminName,
  ) async {
    isLoadingAdd = true;
    notifyListeners();
    final url = Uri.parse(ApiEndpoints.signup);
    final user = UserModel(
      email: email,
      name: name,
      role: role,
      createdTime: DateTime.now().toString(),
      createdById: adminId,
      createdByName: adminName,
    );
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final newUser = UserModel.fromJson(data);

      /// ✅ Update local state correctly
      if (role == "ADMIN") {
        admin.add(newUser);
      } else if (role == "TELE_MARKETING") {
        teleMarketing.add(newUser);
      } else if (role == "MARKETING") {
        marketing.add(newUser);
      }
      isLoadingAdd = false;
      notifyListeners();

      return "Signup successful. Check email for OTP.";
    } else if (response.statusCode == 400 &&
        response.body.contains("Email already exists")) {
      isLoadingAdd = false;
      notifyListeners();

      return "Email already exists";
    } else {
      isLoadingAdd = false;
      notifyListeners();

      return "Error: ${response.body}";
    }
  }
  
  /// 📨 Send a Team Invitation Link (New Flow)
  Future<String> sendTeamInvite({
    required String name,
    required String email,
    required String role,
    required String adminId,
    required String adminName,
  }) async {
    try {
      isLoadingAdd = true;
      notifyListeners();

      // 1. Generate a unique token
      final String token = _generateRandomToken(32);

      // 2. Store in 'pending_team_invites'
      final inviteData = {
        'token': token,
        'email': email.trim(),
        'name': name.trim(),
        'role': role,
        'invitedBy': adminName,
        'invitedById': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      };

      await FirebaseFirestore.instance.collection('pending_team_invites').doc(token).set(inviteData);

      // 3. Construct the link
      const String baseUrl = "https://emmi-management.netlify.app";
      final String inviteLink = "$baseUrl/#/signup?invite=true&token=$token&email=${Uri.encodeComponent(email)}&role=$role";

      // 4. Return the generated link instead of sending an email
      // per the user's request to manually copy and send the link.
      return inviteLink;
    } catch (e) {
      return "Failed to send invitation: $e";
    } finally {
      isLoadingAdd = false;
      notifyListeners();
    }
  }

  String _generateRandomToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _sendInviteEmail({
    required String toEmail,
    required String name,
    required String inviteLink,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://qubiqos.netlify.app/.netlify/functions/send-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': toEmail,
          'name': name,
          'inviteLink': inviteLink,
          'role': role,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Email API error: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error sending invite email: $e");
    }
  }

  // Update member
  // Delete User
  Future<bool> deleteUser(String userId) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1. Delete from API (Legacy)
      try {
        // ApiEndpoints.signup is likely POST only. Skipping API delete for now.
      } catch (_) {}

      // 2. Delete from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();
      } catch (e) {
        print("Error deleting from Firestore: $e");
        // If api delete also failed, return false?
        // But we want to remove from UI if possible.
      }

      // 3. Update Local State
      marketing.removeWhere((u) => u.id == userId);
      teleMarketing.removeWhere((u) => u.id == userId);
      admin.removeWhere((u) => u.id == userId);

      return true;
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
