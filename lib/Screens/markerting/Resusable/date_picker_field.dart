import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool editable;
  final bool allowPastDates;
  final bool showTime; // <--- NEW
  final bool showDate; // <--- NEW
  final IconData icon;

  const DatePickerField({
    super.key,
    required this.label,
    required this.controller,
    this.editable = true,
    this.allowPastDates = true,
    this.showTime = false, // <--- added
    this.showDate = true, // <--- added
    this.icon = Icons.calendar_month,
  });

  Future<void> _pickDateTime(BuildContext context) async {
    if (!editable) return;

    DateTime now = DateTime.now();
    DateTime? selected = now;

    // ---------- DATE PICK ----------
    if (showDate) {
      selected = await showDatePicker(
        context: context,
        initialDate: controller.text.isNotEmpty ? _parse(controller.text) : now,
        firstDate: allowPastDates ? DateTime(2000) : now,
        lastDate: DateTime(2100),
      );

      if (selected == null) return; // cancelled
    }

    // ---------- TIME PICK ----------
    if (showTime) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selected ?? now),
      );

      if (selectedTime == null) return;

      selected = DateTime(
        selected!.year,
        selected.month,
        selected.day,
        selectedTime.hour,
        selectedTime.minute,
        0, // seconds
      );
    }

    // ---------- FINAL FORMAT ----------
    if (showDate && showTime) {
      controller.text = DateFormat("dd-MM-yyyy HH:mm:ss").format(selected!);
    } else if (showDate) {
      controller.text = DateFormat("dd-MM-yyyy").format(selected!);
    } else if (showTime) {
      controller.text = DateFormat("HH:mm:ss").format(selected!);
    }
  }

  // Parses dd-MM-yyyy HH:mm:ss or dd-MM-yyyy
  static DateTime _parse(String text) {
    try {
      if (text.contains(" ")) {
        return DateFormat("dd-MM-yyyy HH:mm:ss").parse(text);
      }
      return DateFormat("dd-MM-yyyy").parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickDateTime(context),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: editable ? Colors.black : Colors.grey,
            ),
            filled: true,
            fillColor: editable ? Colors.grey.shade100 : Colors.grey.shade300,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          style:
              TextStyle(color: editable ? Colors.black : Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
