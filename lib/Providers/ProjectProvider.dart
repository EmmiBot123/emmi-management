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

  Future<bool> updateProject(Project project) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/api/projects/${project.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(project.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchProjects();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating project: $e");
      return false;
    }
  }

  Future<void> syncProjectToQubiq(Project project) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.renderBaseUrl}/admin/sync-project"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key":
              "b256f7241feee8f2626d617e4875ca385c47c9fc97b99bd3a6469a84064eff7c",
        },
        body: jsonEncode({
          "projectId": project.id,
          ...project.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Project Sync Success: ${project.title}");
      } else {
        debugPrint(
            "❌ Project Sync Failed for ${project.title}: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Project Sync Exceptional Error for ${project.title}: $e");
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
