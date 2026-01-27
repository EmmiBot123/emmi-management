import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  String? _userId;
  String? _email;
  String? _name;

  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;

  bool get isLoggedIn => _token != null;

  Future<void> saveLoginData({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _token = token;
    _role = user["role"];
    _userId = user["id"];
    _email = user["email"];
    _name = user["name"];

    await prefs.setString("token", _token!);
    await prefs.setString("role", _role ?? "");
    await prefs.setString("userId", _userId ?? "");
    await prefs.setString("email", _email ?? "");
    await prefs.setString("name", _name ?? "");

    notifyListeners();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString("token");
    _role = prefs.getString("role");
    _userId = prefs.getString("userId");
    _email = prefs.getString("email");
    _name = prefs.getString("name");

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _token = null;
    _role = null;
    _userId = null;
    _email = null;
    _name = null;

    notifyListeners();
  }
}
