class ApiEndpoints {
  static const String baseUrl = "http://35.154.150.95:3000";
  static const String renderBaseUrl =
      "https://edu-ai-backend-vl7s.onrender.com";

  static const String getUsers = "$baseUrl/users";
  static const String signup = "$baseUrl/auth/signup";
  static const String login = "$baseUrl/auth/login";
  static String getUsersByAdminId(String adminId) =>
      "$baseUrl/users/admin/$adminId";
  static String getUsersById(String userId) => "$baseUrl/users/$userId";
  static String createVisit = "$baseUrl/api/school-visits";
  static String getVisitsByID(String userId) =>
      "$baseUrl/api/school-visits/user/$userId";
  static String getVisitsBySharedId(String userId) =>
      "$baseUrl/api/school-visits/shared/$userId";
  static String updateVisit(String id) => "$baseUrl/api/school-visits/$id";
  static String deleteVisit(String id) => "$baseUrl/api/school-visits/$id";
  static String deleteFile(String visitId, String file) =>
      "$baseUrl/api/visits-image/$visitId/delete-file/$file";
  static String deleteFileFolder(String visitId) =>
      "$baseUrl/api/visits-image/$visitId/delete-folder";
  static String imageVisit(String visitID) =>
      "$baseUrl/api/visits-image/$visitID/upload-image";

  static String syncSchool = "$renderBaseUrl/admin/sync-school";
  static String syncCourse = "$renderBaseUrl/admin/sync-course";
  static String getAdmin(String schoolId) => "$renderBaseUrl/admin/get-admin/$schoolId";
  static String discoverySync = "$renderBaseUrl/admin/discovery-sync";

// You can add more later:
// static const String createUser = "$baseUrl/users/create";
// static const String login = "$baseUrl/auth/login";
}
