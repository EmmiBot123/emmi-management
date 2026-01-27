import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

Future<void> fillCurrentLocation(
    TextEditingController controller, BuildContext context) async {
  try {
    // 1️⃣ Check if GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw "Location services are disabled.";
    }

    // 2️⃣ Request Permission if needed
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw "Location permission permanently denied. Enable it from settings.";
    }

    // 3️⃣ Fetch current location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4️⃣ Create Google Maps URL
    final link =
        "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

    // 5️⃣ Write to field
    controller.text = link;

    // Optional feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("GPS location added ✔")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to fetch location: $e")),
    );
  }
}
