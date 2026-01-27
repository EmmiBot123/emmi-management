import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MiniLocationPicker extends StatefulWidget {
  final Function(double lat, double long, String url) onLocationPicked;
  final double? initialLat;
  final double? initialLong;
  final bool editable;

  const MiniLocationPicker({
    super.key,
    required this.onLocationPicked,
    this.initialLat,
    this.initialLong,
    this.editable = true,
  });

  @override
  State<MiniLocationPicker> createState() => _MiniLocationPickerState();
}

class _MiniLocationPickerState extends State<MiniLocationPicker>
    with AutomaticKeepAliveClientMixin {
  final mapController = MapController();
  LatLng? currentPos;

  final latCtrl = TextEditingController();
  final longCtrl = TextEditingController();

  String? googleLink;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLong != null) {
      updateLocation(widget.initialLat!, widget.initialLong!, moveMap: false);
    }
  }

  void updateLocation(double lat, double long, {bool moveMap = true}) {
    setState(() {
      currentPos = LatLng(lat, long);
      googleLink = "https://www.google.com/maps?q=$lat,$long";

      latCtrl.text = lat.toStringAsFixed(6);
      longCtrl.text = long.toStringAsFixed(6);
    });

    widget.onLocationPicked(lat, long, googleLink!);

    if (moveMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            mapController.move(currentPos!, 16);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> getGPS() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw "Location services disabled";

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        throw "Permission permanently denied";
      }

      final position = await Geolocator.getCurrentPosition();
      updateLocation(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              clipBehavior: Clip.hardEdge,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: currentPos ?? const LatLng(20.5937, 78.9629),
                  initialZoom: currentPos == null ? 4 : 16,
                  onTap: widget.editable
                      ? (tapPos, latLng) =>
                          updateLocation(latLng.latitude, latLng.longitude)
                      : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.emmimanagement.app',
                  ),
                  if (currentPos != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentPos!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (widget.editable)
              ElevatedButton.icon(
                onPressed: getGPS,
                icon: const Icon(Icons.my_location),
                label: const Text("GPS"),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.editable)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: latCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Latitude"),
                  onSubmitted: (_) => _manualSet(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: longCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Longitude"),
                  onSubmitted: (_) => _manualSet(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: _manualSet,
              )
            ],
          ),
        if (googleLink != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(googleLink!)),
            child: Text(
              googleLink!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        ]
      ],
    );
  }

  void _manualSet() {
    if (latCtrl.text.isNotEmpty && longCtrl.text.isNotEmpty) {
      updateLocation(
        double.parse(latCtrl.text),
        double.parse(longCtrl.text),
      );
    }
  }
}
