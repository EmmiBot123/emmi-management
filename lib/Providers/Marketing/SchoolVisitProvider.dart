import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Marketing/ParsedAddress.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Model/productDetails/ProductOption.dart';
import '../../Model/productDetails/SerialAssignment.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Resources/api_endpoints.dart';

class SchoolVisitProvider extends ChangeNotifier {
  final SchoolVisitRepository repository = SchoolVisitRepository();

  List<SchoolVisit> visits = [];
  List<SchoolVisit> filteredVisits = [];
  List<SchoolVisit> paymentVisits = [];
  List<SchoolVisit> assemblyVisits = [];
  List<SchoolVisit> installationVisits = [];
  List<ProductOption> availableProducts = [];

  bool isLoading = false;
  String? errorMessage;
  String? currentFilter = "ALL";
  double _distanceKm({
    required double userLat,
    required double userLng,
    required double schoolLat,
    required double schoolLng,
  }) {
    return Geolocator.distanceBetween(
          userLat,
          userLng,
          schoolLat,
          schoolLng,
        ) /
        1000;
  }

  double nearbyRadiusKm = 100;
  bool isNearbyMode = false;

  void clear() {
    visits = [];
    filteredVisits = [];
    paymentVisits = [];
    assemblyVisits = [];
  }

  /// Load visit records using FULL URL
  Future<void> loadVisits(String userId) async {
    try {
      isLoading = true;
      notifyListeners();
      currentFilter = "ALL";
      visits = await repository.getVisits(userId);

      // 🔥 Newest → Oldest (null-safe)
      visits.sort((a, b) {
        final DateTime dateA =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return dateB.compareTo(dateA);
      });

      filteredVisits = visits;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  DateTime parseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      // Convert "yyyy-MM-dd HH:mm:ss" → ISO format
      final fixed = date.replaceFirst(' ', 'T');
      return DateTime.parse(fixed);
    }
  }

  /////////////////////////////////////
  //// NEARBY LOCATION FILTER ////////
  ///////////////////////////////////

  Future<void> getNearbySchools(double radiusKm) async {
    try {
      isLoading = true;
      notifyListeners();

      final position = await _getCurrentLocation();

      filteredVisits = visits.where((visit) {
        final school = visit.schoolProfile;

        final distance = _distanceKm(
          userLat: position.latitude,
          userLng: position.longitude,
          schoolLat: school.latitude,
          schoolLng: school.longitude,
        );

        return distance <= radiusKm;
      }).toList();

      // Sort nearest → farthest
      filteredVisits.sort((a, b) {
        final d1 = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          a.schoolProfile.latitude,
          a.schoolProfile.longitude,
        );

        final d2 = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          b.schoolProfile.latitude,
          b.schoolProfile.longitude,
        );

        return d1.compareTo(d2);
      });

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> enableNearbyMode(double radiusKm) async {
    nearbyRadiusKm = radiusKm;
    isNearbyMode = true;
    await getNearbySchools(radiusKm);
  }

  void disableNearbyMode({bool notify = true}) {
    isNearbyMode = false;
    filteredVisits = visits;

    if (notify) {
      notifyListeners();
    }
  }

//////////////////////////////////////////////
//////////////////////////////////////////////

  Future<void> loadPaymentVisits() async {
    try {
      isLoading = true;
      notifyListeners();
      final visits = await repository.getPaymentVisits();

      paymentVisits = visits
          .where((v) =>
              v.visitDetails.status.toUpperCase() == "CLOSED_WON" ||
              v.payment.advanceTransferred == true)
          .toList();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAssemblyVisits() async {
    try {
      isLoading = true;
      notifyListeners();
      final visits = await repository.getPaymentVisits();

      assemblyVisits = visits
          .where((v) =>
              v.visitDetails.status == "CLOSED_WON" &&
              v.payment.paymentConfirmed == true)
          .toList();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadInstallationVisits() async {
    try {
      isLoading = true;
      notifyListeners();
      final visits = await repository.getPaymentVisits();

      installationVisits = visits
          .where((v) =>
              v.visitDetails.status == "CLOSED_WON" &&
              v.shippingDetails.passedToInstallation == true)
          .toList();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveSerialAssignment(SerialAssignment model) async {
    bool firestoreOk = false;
    bool apiOk = false;

    // 1. Save to Firestore (Reliable Backup)
    try {
      final docId = model.id ??
          FirebaseFirestore.instance.collection('serial_assignments').doc().id;
      model.id = docId;

      await FirebaseFirestore.instance
          .collection('serial_assignments')
          .doc(docId)
          .set(model.toJson(), SetOptions(merge: true));
      firestoreOk = true;
      print("✅ SerialAssignment Saved to Firestore");
    } catch (e) {
      print("❌ Firestore Serial Save Failed: $e");
    }

    // 2. Save to Legacy API
    try {
      final url = "${ApiEndpoints.baseUrl}/api/serials/save";
      final uri = Uri.parse(url);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(model.toJson()),
      );
      apiOk = response.statusCode == 200 || response.statusCode == 201;
      if (apiOk) print("✅ SerialAssignment Saved to API");
    } catch (e) {
      print("❌ API Serial Save Failed: $e");
    }

    return firestoreOk || apiOk;
  }

  Future<SerialAssignment?> getSerialAssignmentByVisit(String visitId) async {
    // 1. Try Firestore First (Handles CORS/Connection issues)
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('serial_assignments')
          .where('visitId', isEqualTo: visitId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        print("✅ Loaded SerialAssignment from Firestore");
        return SerialAssignment.fromJson(data);
      }
    } catch (e) {
      print("❌ Firestore Serial Fetch Failed: $e");
    }

    // 2. Fallback to API
    try {
      final url = "${ApiEndpoints.baseUrl}/api/serials/visit/$visitId";
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty) {
          final map = json.first as Map<String, dynamic>;
          print("✅ Loaded SerialAssignment from API");
          return SerialAssignment.fromJson(map);
        }
      }
    } catch (e) {
      print("❌ API Serial Fetch Failed: $e");
    }

    return null;
  }

  Future<List<ProductOption>> fetchAvailableProducts() async {
    try {
      final url = "${ApiEndpoints.baseUrl}/api/products";
      final uri = Uri.parse(url);

      final response = await http.get(uri);

      print("🔵 Fetch Products API: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          availableProducts =
              data.map((e) => ProductOption.fromJson(e)).toList();

          print("🟢 Parsed Products = ${availableProducts.length}");
          return availableProducts;
        }
      }

      availableProducts = [];
      return [];
    } catch (e) {
      availableProducts = [];
      print("❌ fetchAvailableProducts ERROR: $e");
      return [];
    }
  }

  /// Create new record
  Future<bool> addVisit(SchoolVisit visit) async {
    try {
      isLoading = true;
      notifyListeners();

      await repository.createVisit(visit);

      // 🔥 Add newest visit at the top
      visits.insert(0, visit);

      filterByStatus(currentFilter!);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update record
  Future<bool> updateVisit(SchoolVisit visit) async {
    try {
      isLoading = true;
      notifyListeners();

      await repository.updateVisit(visit);
      final index = visits.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        visits[index] = visit;
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete by FULL URL
  Future<bool> deleteVisit(String userId) async {
    try {
      isLoading = true;
      notifyListeners();

      await repository.deleteVisit(userId);

      // 🔥 Remove from local lists
      visits.removeWhere((v) => v.id == userId);
      filteredVisits.removeWhere((v) => v.id == userId);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVisitPhotos(String userId) async {
    try {
      notifyListeners();

      await repository.deleteVisitFiles(userId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  void removeVisit(String userId) {
    visits.removeWhere((item) => item.id == userId);
    filteredVisits.removeWhere((item) => item.id == userId);
    notifyListeners();
  }

  Future<String?> uploadVisitImage({
    required String visitId,
    required String filePath,
    required XFile pickedFile, // PASS XFile instead of only path
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.imageVisit(visitId));
      var request = http.MultipartRequest("POST", uri);

      if (kIsWeb) {
        // --- Web Upload ---
        Uint8List bytes = await pickedFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: pickedFile.name,
          ),
        );
      } else {
        // --- Mobile Upload ---
        request.files.add(await http.MultipartFile.fromPath("file", filePath));
      }

      final response = await request.send();

      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return body.trim();
      }

      return null;
    } catch (e) {
      print("UPLOAD ERROR: $e");
      return null;
    }
  }

  Future<bool> deleteVisitImage({
    required String visitId,
    required String fileName, // extracted from URL
  }) async {
    try {
      final url = ApiEndpoints.deleteFile(visitId, fileName);
      final uri = Uri.parse(url);
      print(url);
      final response = await http.delete(uri);
      print(response.body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void filterByStatus(String status) {
    currentFilter = status;
    filteredVisits = [];
    if (status == "ALL") {
      filteredVisits = visits;
    } else if (status == "PENDING") {
      filteredVisits =
          visits.where((v) => v.visitDetails.status == status).toList();
    } else if (status == "APPROVED") {
      filteredVisits =
          visits.where((v) => v.visitDetails.status == status).toList();
    } else if (status == "REJECTED") {
      filteredVisits =
          visits.where((v) => v.visitDetails.status == status).toList();
    } else if (status == "REVISIT") {
      filteredVisits =
          visits.where((v) => v.visitDetails.status == status).toList();
    }
    notifyListeners();
  }

  Future<void> filterSharedVisits(String userId) async {
    currentFilter = "SHARED";

    try {
      isLoading = true;
      notifyListeners();
      filteredVisits = [];
      filteredVisits = await repository.getVisitsShared(userId);

      // 🔥 Newest → Oldest (null-safe)
      filteredVisits.sort((a, b) {
        final DateTime dateA =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime dateB =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return dateB.compareTo(dateA);
      });

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<ParsedAddress?> getAddressFromOSM(double lat, double lon) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json");

    final response = await http.get(url, headers: {
      "User-Agent": "emmi-management-app/1.0" // Required by OSM policy
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ParsedAddress.fromJson(jsonData);
    }

    return null;
  }
}
