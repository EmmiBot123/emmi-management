import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Providers/AuthProvider.dart';

class AuthService {
  final String baseUrl = 'http://35.154.150.95:3000';

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required AuthProvider authProvider,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      final payload = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        final token = result['token'];
        final user = result['user'];

        authProvider.saveLoginData(
          token: token,
          user: user,
        );

        return result;
      } else {
        throw Exception("Login failed: ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> verifyEmailRequest({
    required String email,
    required AuthProvider authProvider,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final payload = {
      'email': email,
    };
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return response.body;
  }

  Future<void> completeRegistration({
    required String email,
    required String otp,
    required String password,
    required String phone,
    required AuthProvider authProvider,
  }) async {
    final url = Uri.parse("$baseUrl/auth/verify");

    final body = {
      "email": email,
      "verificationCode": otp,
      "password": password,
      "phone": phone
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw res.body;
    }
  }
}
