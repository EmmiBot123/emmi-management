import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Resources/theme_constants.dart';
import '../../markerting/SchoolVisit/MapPicker.dart';

class SchoolInfoPage extends StatefulWidget {
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

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  bool _isEditing = false;

  Widget _buildInfoCard(String label, TextEditingController c, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isEditing)
                  TextField(
                    controller: c,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "Enter value...",
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  )
                else
                  Text(
                    c.text.isEmpty ? "N/A" : c.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (!_isEditing && label.toLowerCase().contains("address"))
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: c.text));
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Address copied to clipboard"), duration: Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("School Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isEditing = !_isEditing;
                });
                if (!_isEditing) {
                  // User clicked 'SAVE'
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Changes synchronized locally")),
                  );
                }
              },
              icon: Icon(_isEditing ? Icons.check_circle_outline : Icons.edit_note_rounded, color: AppColors.accent, size: 20),
              label: Text(_isEditing ? "SAVE" : "EDIT", style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accent.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: widget.schoolCtrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "School Name"),
                      ),
                    )
                  else
                    Text(
                      widget.schoolCtrl.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditing ? "Modify registry details" : "Institution Registry Details",
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              "GENERAL INFORMATION",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),

            if (!_isEditing) _buildInfoCard("School Name", widget.schoolCtrl, Icons.business_rounded),
            _buildInfoCard("Complete Address", widget.addressCtrl, Icons.location_on_rounded),
            
            Row(
              children: [
                Expanded(child: _buildInfoCard("City", widget.cityCtrl, Icons.location_city_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildInfoCard("State", widget.stateCtrl, Icons.map_rounded)),
              ],
            ),
            
            _buildInfoCard("Pincode", widget.pinCtrl, Icons.pin_drop_rounded),

            const SizedBox(height: 24),
            
            const Text(
              "GEOLOCATION PREVIEW",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),

            Container(
              height: 250, // Increased height to prevent overflow
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              clipBehavior: Clip.antiAlias,
              child: MiniLocationPicker(
                editable: false,
                initialLat: widget.lat,
                initialLong: widget.long,
                onLocationPicked: (_, __, ___) {},
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


