import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../../Model/Task_model.dart';
import '../../Model/Support/support_ticket_model.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Repository/Support/support_repository.dart';
import 'qubiq_page.dart';
import '../Support/support_ticket_list_page.dart';

class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF8B5CF6); // Purple for QubiQ
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
}

class QubiqManagerDashboardPage extends StatefulWidget {
  const QubiqManagerDashboardPage({super.key});

  @override
  State<QubiqManagerDashboardPage> createState() => _QubiqManagerDashboardPageState();
}

class _QubiqManagerDashboardPageState extends State<QubiqManagerDashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _totalSchools = 0;
  int _openTicketsCount = 0;
  List<SupportTicket> _recentTickets = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
    _fetchMetrics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    try {
      // 1. Fetch Total Schools
      final schoolRepo = SchoolVisitRepository();
      final visits = await schoolRepo.getPaymentVisits();
      final confirmed = visits.where((v) => v.payment.paymentConfirmed).toList();
      _totalSchools = confirmed.length;

      // 2. Fetch Tickets
      final supportRepo = SupportRepository();
      final tickets = await supportRepo.getAllTickets();
      
      final openTickets = tickets.where((t) => t.status == 'open').toList();
      _openTicketsCount = openTickets.length;

      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _recentTickets = tickets.take(5).toList();

      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    } catch (e) {
      debugPrint("Error fetching QubiQ metrics: $e");
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildTasksSection(context)),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildTicketsSection()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.name ?? "QubiQ Team";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("QubiQ Hub", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text("Welcome back, $userName. Oversee the network.", style: const TextStyle(color: _C.textSecondary, fontSize: 15)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.accent.withValues(alpha: 0.2))),
          child: const Row(
            children: [
              Icon(Icons.hub, color: _C.accent, size: 18),
              SizedBox(width: 8),
              Text("QubiQ Manager", style: TextStyle(color: _C.accent, fontWeight: FontWeight.bold, fontSize: 13)),
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
            final isForDept = t.assigneeType == 'Department' && t.assignedToId == 'QUBIQ';
            final isForMe = t.assigneeType == 'Person' && t.assignedToId == myId;
            return (isForDept || isForMe) && t.status != 'Completed';
          }).length;
        }

        if (_isLoadingMetrics) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _C.accent)));
        }

        return Row(
          children: [
            Expanded(child: _buildMetricCard("QubiQ Network", _totalSchools.toString(), Icons.domain, _C.accent)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Open Issues", _openTicketsCount.toString(), Icons.confirmation_number, _C.warning)),
            const SizedBox(width: 16),
            Expanded(child: _buildMetricCard("Dept Tasks", openTasks.toString(), Icons.assignment, _C.danger)),
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
                "Configure Network",
                "Add domains & set up schools",
                Icons.api,
                _C.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => QubiqPage())),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                "Resolve Issues",
                "View and manage support tickets",
                Icons.support_agent,
                _C.warning,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketListPage())),
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
                return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(color: _C.accent)));
              }

              final allTasks = snapshot.data ?? [];
              final auth = context.watch<AuthProvider>();
              final myId = auth.userId;

              final tasks = allTasks.where((t) {
                final isForDept = t.assigneeType == 'Department' && t.assignedToId == 'QUBIQ';
                final isForMe = t.assigneeType == 'Person' && t.assignedToId == myId;
                return isForDept || isForMe;
              }).toList();

              if (tasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("No tasks currently assigned to QubiQ.", style: TextStyle(color: _C.textMuted)),
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
                        Container(
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

  Widget _buildTicketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Tickets", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketListPage())),
              child: const Text("View All", style: TextStyle(color: _C.accent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: _isLoadingMetrics
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _C.accent)))
              : _recentTickets.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No tickets found.", style: TextStyle(color: _C.textMuted))))
                  : Column(
                      children: _recentTickets.map((t) {
                        final isOpen = t.status == 'open';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isOpen ? _C.warning.withValues(alpha: 0.1) : _C.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(t.isHardwareComplaint ? Icons.build : Icons.confirmation_number, color: isOpen ? _C.warning : _C.success, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.email, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(t.message, style: const TextStyle(color: _C.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }
}
