import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Model/Course.dart';
import '../Resources/api_endpoints.dart';

class CourseProvider extends ChangeNotifier {
  List<Course> _courses = [];
  bool _isLoading = false;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;

  Future<void> fetchCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/courses"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _courses = data.map((json) => Course.fromJson(json)).toList();
      } else {
        debugPrint("Failed to fetch courses: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCourse(Course course) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/courses"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(course.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newCourseJson = jsonDecode(response.body);
        final newCourse = Course.fromJson(newCourseJson);
        
        // 🔄 Sync to Qubiq Firebase
        await syncCourseToQubiq(newCourse);
        
        await fetchCourses();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding course: $e");
      return false;
    }
  }

  Future<void> syncCourseToQubiq(Course course) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.syncCourse),
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c",
        },
        body: jsonEncode({
          "courseId": course.id,
          ...course.toJson(), // Send everything: name, description, category, price, duration, learningPoints, curriculum, imageUrl, level, language
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Course Sync Success: ${course.name}");
      } else {
        debugPrint(
            "❌ Course Sync Failed for ${course.name}: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Course Sync Exceptional Error for ${course.name}: $e");
    }
  }

  Future<bool> deleteCourse(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/courses/$id"),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _courses.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting course: $e");
      return false;
    }
  }
}
