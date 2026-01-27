import 'package:geolocator/geolocator.dart';

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
