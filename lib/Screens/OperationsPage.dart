import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Resources/theme_constants.dart';
import 'Assembly/School_assembly_page.dart';
import 'Installation/installation_dashboard.dart';
import 'Installation/installation_team_page.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> with SingleTickerProviderStateMixin {
  int _tabIndex = 1; 
  late AnimationController _heroController;
  late Animation<double> _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroAnim = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userRole = auth.role ?? "";

    if (userRole == "ASSEMBLY_TEAM") return const SchoolAssemblyPage();
    if (userRole == "INSTALLATION_TEAM") return const InstallationDashboard();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Operations",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.accent, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header Segment (Toggle) ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Qubiq OS Workflow Engine",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      _buildSegment("Assembly", Icons.build_circle_outlined, 0),
                      _buildSegment("Installation", Icons.engineering_outlined, 1),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey(_tabIndex),
                child: _tabIndex == 0 ? const SchoolAssemblyPage() : const InstallationDashboard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, IconData icon, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? AppColors.accent : AppColors.textMuted),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppColors.textPrimary : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
