import '../Model/Marketing/school_visit_model.dart';
import '../Resources/api_endpoints.dart';
import '../Services/api_service/api_service.dart';

class SchoolVisitRepository {
  final ApiService api = ApiService();

  /// GET All by UserId using AppConfig URL
  Future<List<SchoolVisit>> getVisits(String userId) async {
    final url = ApiEndpoints.getVisitsByID(userId);
    final response = await api.get(url);
    return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
  }

  Future<List<SchoolVisit>> getVisitsShared(String userId) async {
    final url = ApiEndpoints.getVisitsBySharedId(userId);
    final response = await api.get(url);
    return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
  }

  /// GET All by UserId using AppConfig URL
  Future<List<SchoolVisit>> getPaymentVisits() async {
    final url = ApiEndpoints.createVisit;
    final response = await api.get(url);
    return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
  }

  /// CREATE Visit
  Future<bool> createVisit(SchoolVisit visit) async {
    final url = ApiEndpoints.createVisit;
    await api.post(url, visit.toJson());
    return true;
  }

  /// UPDATE Visit
  Future<bool> updateVisit(SchoolVisit visit) async {
    if (visit.id == null) throw Exception("Visit ID missing!");

    final url = ApiEndpoints.updateVisit(visit.id!);
    await api.put(url, visit.toJson());
    return true;
  }

  /// DELETE Visit
  Future<bool> deleteVisit(String id) async {
    final url = ApiEndpoints.deleteVisit(id);
    await api.delete(url);
    return true;
  }

  Future<bool> deleteVisitFiles(String id) async {
    final url = ApiEndpoints.deleteFileFolder(id);
    await api.delete(url);
    return true;
  }
}
