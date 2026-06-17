import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../../Providers/CourseProvider.dart';
import '../../Model/Task_model.dart';
import '../../Repository/school_visit_repository.dart';
import '../OperationsPage.dart';
import '../ContentHub/content_hub_page.dart';
import '../Qubiq/qubiq_page.dart';

class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF0EA5E9); // Sky blue for Deployment
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class DeploymentDashboardPage extends StatefulWidget {
  const DeploymentDashboardPage({super.key});

  @override
  State<DeploymentDashboardPage> createState() => _DeploymentDashboardPageState();
}

class _DeploymentDashboardPageState extends State<DeploymentDashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _pendingInstalls = 0;
  int _schoolsConfigured = 0;
  int _activeCourses = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    try {
      final repo = SchoolVisitRepository();
      final visits = await repo.getPaymentVisits();
      
      int pending = 0;
      int configured = 0;
      for (var v in visits) {
        if (v.payment.paymentConfirmed) {
          configured++;
        } else {
          pending++;
        }
      }

      final courseProvider = context.read<CourseProvider>();
      await courseProvider.fetchCourses();
      final active = courseProvider.courses.length;

      if (mounted) {
        setState(() {
          _pendingInstalls = pending;
          _schoolsConfigured = configured;
          _activeCourses = active;
        });
      }
    } catch (e) {
      debugPrint("Error fetching deployment metrics: $e");
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildMetricsStrip(),
              const SizedBox(height: 40),
              _buildQuickActions(context),
              const SizedBox(height: 40),
              _buildTasksSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.name ?? "Deployment Team";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Deployment Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text("Welcome back, $userName. Ready to setup some schools?", style: const TextStyle(color: _C.textSecondary, fontSize: 15)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.accent.withValues(alpha: 0.2))),
          child: const Row(
            children: [
              Icon(Icons.rocket_launch, color: _C.accent, size: 18),
              SizedBox(width: 8),
              Text("Deployment Manager", style: TextStyle(color: _C.accent, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMetricsStrip() {
    return StreamBuilder<List<TaskModel>>(
      stream: context.read<TaskProvider>().tasksStream,
      builder: (context, snapshot) {
        int openTasks = 0;
        if (snapshot.hasData) {
          final auth = context.read<AuthProvider>();
          final myId = auth.userId;
          openTasks = snapshot.data!.where((t) {
            final isForDept = t.assigneeType == 'Department' && t.assignedToId == 'DEPLOYMENT';
            final isForMe = t.assigneeType == 'Person' && t.assignedToId == myId;
            return (isForDept || isForMe) && t.status != 'Completed';
          }).length;
        }

        return Row(
          children: [
            Expanded(child: _buildMetricCard("Pending Installs", _pendingInstalls.toString(), Icons.build_circle, _C.warning)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Schools Configured", _schoolsConfigured.toString(), Icons.business, _C.accent)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Active Courses", _activeCourses.toString(), Icons.menu_book, _C.success)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Open Tasks", openTasks.toString(), Icons.assignment, _C.danger)),
          ],
        );
      }
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _C.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                "Configure QubiQ",
                "Setup domains and school data",
                Icons.api,
                _C.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => QubiqPage())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                "Manage Courses",
                "Upload and link content hubs",
                Icons.school,
                _C.success,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentHubPage())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                "Operations",
                "Log assembly & installations",
                Icons.engineering,
                _C.warning,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: _C.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Delegated Tasks", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: StreamBuilder<List<TaskModel>>(
            stream: context.read<TaskProvider>().tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _C.accent));
              }

              final allTasks = snapshot.data ?? [];
              final auth = context.watch<AuthProvider>();
              final myId = auth.userId;

              final tasks = allTasks.where((t) {
                final isForDept = t.assigneeType == 'Department' && t.assignedToId == 'DEPLOYMENT';
                final isForMe = t.assigneeType == 'Person' && t.assignedToId == myId;
                return isForDept || isForMe;
              }).toList();

              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text("No tasks currently assigned to Deployment.", style: TextStyle(color: _C.textMuted)),
                  ),
                );
              }

              return Column(
                children: tasks.map((task) {
                  Color priorityColor;
                  switch (task.priority) {
                    case 'High': priorityColor = _C.danger; break;
                    case 'Low': priorityColor = _C.success; break;
                    default: priorityColor = _C.warning;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        left: BorderSide(color: priorityColor, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(task.assigneeType == 'Department' ? Icons.business : Icons.person, color: priorityColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(task.description, style: const TextStyle(color: _C.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            // Task status update logic to be implemented later
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: task.status == 'Completed' ? _C.success.withValues(alpha: 0.1) : _C.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: task.status == 'Completed' ? _C.success : _C.textMuted),
                            ),
                            child: Text(
                              task.status,
                              style: TextStyle(color: task.status == 'Completed' ? _C.success : _C.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
