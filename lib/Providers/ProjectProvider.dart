import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Model/Project.dart';
import '../Resources/api_endpoints.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> fetchProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/projects"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _projects = data.map((json) => Project.fromJson(json)).toList();
      } else {
        debugPrint("Failed to fetch projects: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProject(Project project) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/projects"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(project.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newProjectJson = jsonDecode(response.body);
        final newProject = Project.fromJson(newProjectJson);
        
        // 🔄 Sync to Qubiq Firebase (if endpoint exists later)
        // await syncProjectToQubiq(newProject);
        
        await fetchProjects();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding project: $e");
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/projects/$id"),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _projects.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting project: $e");
      return false;
    }
  }
}
