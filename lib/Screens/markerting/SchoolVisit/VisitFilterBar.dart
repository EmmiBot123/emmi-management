import 'package:flutter/material.dart';

class VisitFilterBar extends StatelessWidget {
  final Function(String) onFilter;

  const VisitFilterBar({super.key, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _filterButton("All", Icons.list, Colors.blue),
        _filterButton("Pending", Icons.pending_actions, Colors.orange),
        _filterButton("Approved", Icons.check_circle, Colors.green),
        _filterButton("Rejected", Icons.cancel, Colors.red),
      ].map((btn) => Expanded(child: btn)).toList(),
    );
  }

  Widget _filterButton(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => onFilter(label),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
