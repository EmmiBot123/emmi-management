class ApiEndpoints {
  static const String baseUrl = "http://35.154.150.95:3000";

  static const String getUsers = "$baseUrl/users";
  static const String signup = "$baseUrl/auth/signup";
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

// You can add more later:
// static const String createUser = "$baseUrl/users/create";
// static const String login = "$baseUrl/auth/login";
}
