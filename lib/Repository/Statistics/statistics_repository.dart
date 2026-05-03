import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Providers/AuthProvider.dart';

class StatisticsRepository {
  final String baseUrl = "https://edu-ai-backend-vl7s.onrender.com/admin";
  final String apiKey = "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c";

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/stats"),
        headers: {
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      print("Error fetching global stats: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getSchoolStats(String schoolId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/stats/school/$schoolId"),
        headers: {
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      print("Error fetching school stats: $e");
      return {};
    }
  }
}
