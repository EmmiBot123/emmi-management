import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/Assembly/AssemblyStatsProvider.dart';
import '../GenericTeamPage.dart';
import '../SuperAdmin/ProductManagementPage/ProductManagementPage.dart';
import 'School_assembly_page.dart';

// ─── Color Palette
class _C {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
  static const success = Color(0xFF00D4AA);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFBB55);
}

class AssemblyDashboardPage extends StatefulWidget {
  const AssemblyDashboardPage({super.key});

  @override
  State<AssemblyDashboardPage> createState() => _AssemblyDashboardPageState();
}

class _AssemblyDashboardPageState extends State<AssemblyDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<AssemblyStatsProvider>();

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMetricsSection(context, statsProvider),
                const SizedBox(height: 32),
                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: const Text(
          "Assembly Dashboard",
          style: TextStyle(
            color: _C.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _C.accent.withOpacity(0.1),
                _C.bg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, AssemblyStatsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Overview",
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showUpdateStatsDialog(context, provider),
              icon: const Icon(Icons.edit, color: _C.accent, size: 16),
              label: const Text(
                "Update Metrics",
                style: TextStyle(color: _C.accent, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _C.accent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator(color: _C.accent))
        else
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "Manufactured",
                  value: provider.totalManufactured.toString(),
                  icon: Icons.precision_manufacturing,
                  color: _C.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: "Defective",
                  value: provider.defectiveBots.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: _C.danger,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: "Ready",
                  value: provider.readyToDispatch.toString(),
                  icon: Icons.check_circle_outline,
                  color: _C.success,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(
          title: "Product Management",
          subtitle: "Manage inventory & schemas",
          icon: Icons.inventory_2_outlined,
          color: _C.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductManagementPage()),
            );
          },
        ),
        _buildActionCard(
          title: "Assembly Queue",
          subtitle: "View pending schools",
          icon: Icons.format_list_bulleted_rounded,
          color: _C.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchoolAssemblyPage()),
            );
          },
        ),
        _buildActionCard(
          title: "Team Members",
          subtitle: "View assembly team",
          icon: Icons.people_outline,
          color: _C.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GenericTeamPage(
                  role: "ASSEMBLY_TEAM",
                  title: "Assembly Team",
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.surfaceLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _C.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUpdateStatsDialog(BuildContext context, AssemblyStatsProvider provider) async {
    final mCtrl = TextEditingController(text: provider.totalManufactured.toString());
    final dCtrl = TextEditingController(text: provider.defectiveBots.toString());
    final rCtrl = TextEditingController(text: provider.readyToDispatch.toString());
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _C.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Update Metrics", style: TextStyle(color: _C.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField("Total Manufactured", Icons.precision_manufacturing, mCtrl, _C.accent),
                    const SizedBox(height: 16),
                    _buildDialogField("Defective Bots", Icons.warning_amber, dCtrl, _C.danger),
                    const SizedBox(height: 16),
                    _buildDialogField("Ready to Dispatch", Icons.check_circle_outline, rCtrl, _C.success),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel", style: TextStyle(color: _C.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true);
                    final m = int.tryParse(mCtrl.text) ?? provider.totalManufactured;
                    final d = int.tryParse(dCtrl.text) ?? provider.defectiveBots;
                    final r = int.tryParse(rCtrl.text) ?? provider.readyToDispatch;
                    
                    try {
                      await provider.updateStats(manufactured: m, defective: d, ready: r);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Metrics updated")),
                        );
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildDialogField(String label, IconData icon, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: _C.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _C.textSecondary),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: _C.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
