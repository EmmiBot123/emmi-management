import 'package:flutter/material.dart';
import '../../markerting/SchoolVisit/MapPicker.dart';

class SchoolInfoPage extends StatelessWidget {
  final TextEditingController schoolCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController pinCtrl;
  final double? lat;
  final double? long;

  const SchoolInfoPage({
    super.key,
    required this.schoolCtrl,
    required this.addressCtrl,
    required this.stateCtrl,
    required this.cityCtrl,
    required this.pinCtrl,
    required this.lat,
    required this.long,
  });

  Widget field(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Info")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field("School Name", schoolCtrl),
          field("Address", addressCtrl),
          field("State", stateCtrl),
          field("City", cityCtrl),
          field("Pincode", pinCtrl),
          MiniLocationPicker(
            editable: false,
            initialLat: lat,
            initialLong: long,
            onLocationPicked: (_, __, ___) {},
          )
        ],
      ),
    );
  }
}
