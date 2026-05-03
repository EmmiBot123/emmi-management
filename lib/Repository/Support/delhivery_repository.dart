import 'dart:convert';
import 'package:http/http.dart' as http;

class DelhiveryRepository {
  // This token should ideally be fetched from a secure config or backend.
  // For now, we use a placeholder or the one provided by the user.
  static String apiToken = ""; 

  Future<Map<String, dynamic>?> getTrackingStatus(String awb) async {
    if (apiToken.isEmpty) {
      print("Delhivery API Token is missing.");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse("https://track.delhivery.com/api/v1/packages/json/?waybill=$awb"),
        headers: {
          'Authorization': 'Token $apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ShipmentData'] != null && data['ShipmentData'].isNotEmpty) {
          return data['ShipmentData'][0]['Shipment'];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching Delhivery tracking: $e");
      return null;
    }
  }
}
