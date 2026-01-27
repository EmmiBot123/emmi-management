import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  String? _token;

  /// Optional: attach an auth token
  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  Future<dynamic> get(String url) async {
    return _sendRequest("GET", url);
  }

  Future<dynamic> post(String url, dynamic body) async {
    return _sendRequest("POST", url, body: body);
  }

  Future<dynamic> put(String url, dynamic body) async {
    return _sendRequest("PUT", url, body: body);
  }

  Future<dynamic> delete(String url) async {
    return _sendRequest("DELETE", url);
  }

  /// Core reusable method
  Future<dynamic> _sendRequest(
    String method,
    String url, {
    dynamic body,
  }) async {
    final uri = Uri.parse(url);
    late http.Response response;

    try {
      switch (method) {
        case "GET":
          response = await http
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 10));
          break;

        case "POST":
          response = await http
              .post(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;

        case "PUT":
          response = await http
              .put(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;

        case "DELETE":
          response = await http
              .delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 10));
          break;

        default:
          throw ApiException("HTTP method not supported: $method");
      }

      return _handleResponse(response);
    } catch (e) {
      throw ApiException("Request Failed → $e");
    }
  }

  /// Parse and validate response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        // If not JSON, return as plain text
        return response.body;
      }
    }

    throw ApiException("API Error (${response.statusCode}) → ${response.body}");
  }
}

/// Custom error type
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
