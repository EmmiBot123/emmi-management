import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Model/Marketing_member.dart';
import '../Model/User_model.dart';
import '../Resources/api_endpoints.dart';
import 'AuthProvider.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> marketing = [];
  List<UserModel> teleMarketing = [];
  List<UserModel> admin = [];
  bool isLoading = false;
  bool isLoadingAdd = false;
  Future<void> loadAdmins() async {
    try {
      isLoading = true;
      notifyListeners();

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
      print("Error fetching members => $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load members from API
  Future<void> loadMembers(String adminId) async {
    try {
      isLoading = true;
      notifyListeners();

      final url = Uri.parse(ApiEndpoints.getUsersByAdminId(adminId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);

        final List<UserModel> allUsers =
            jsonList.map((item) => UserModel.fromJson(item)).toList();

        // Filter only marketing members
        marketing = allUsers
            .where((user) =>
                user.role != null && user.role!.toLowerCase() == "marketing")
            .toList();
        teleMarketing = allUsers
            .where((user) =>
                user.role != null &&
                user.role!.toLowerCase() == "tele_marketing")
            .toList();

        // Sort alphabetically by name
        marketing.sort((a, b) => (a.name ?? "")
            .toLowerCase()
            .compareTo((b.name ?? "").toLowerCase()));
        // Sort alphabetically by name
        teleMarketing.sort((a, b) => (a.name ?? "")
            .toLowerCase()
            .compareTo((b.name ?? "").toLowerCase()));
      } else {
        print("API error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching members => $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> loadAdmin(String userID) async {
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

  // Update member
  // Future<void> editMember(String id, String name) async {
  //   // TODO: API PUT request
  //
  //   final index = members.indexWhere((m) => m.id == id);
  //   if (index != -1) {
  //     members[index] = MarketingMember(id: id, name: name);
  //     notifyListeners();
  //   }
  // }
}
