import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Providers/BillProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Model/Bill.dart';
import '../../Model/Task_model.dart';
import 'SchoolVisit/add_visit_page.dart';
import 'SchoolVisit/school_visit_list_page.dart';
import 'SchoolVisit/visit_details_page.dart';
import 'Bills/add_bill_page.dart';
import 'Bills/my_bills_page.dart';
import '../TeleMarketing/TeleMarketing.dart';
import '../CEO/task_work_thread_sheet.dart';

// ─── Modern Obsidian & Amber/Emerald Theme ───
class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const amber = Color(0xFFF59E0B);
  static const emerald = Color(0xFF10B981);
  static const cyan = Color(0xFF38BDF8);
  static const purple = Color(0xFF8B5CF6);
  static const rose = Color(0xFFF43F5E);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
}

class MarketingDashboardPage extends StatefulWidget {
  const MarketingDashboardPage({super.key});

  @override
  State<MarketingDashboardPage> createState() => _MarketingDashboardPageState();
}

class _MarketingDashboardPageState extends State<MarketingDashboardPage> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';
    if (userId.isNotEmpty) {
      context.read<SchoolVisitProvider>().loadVisits(userId);
      context.read<BillProvider>().loadMyBills(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final visitProvider = context.watch<SchoolVisitProvider>();
    final billProvider = context.watch<BillProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final userId = auth.userId ?? '';
    final userName = auth.name ?? 'Field Specialist';
    final userRole = auth.role ?? 'MARKETING';

    final visits = visitProvider.visits;
    final bills = billProvider.myBills;

    // Metrics Calculations
    final totalVisits = visits.length;
    final confirmedCount = visits.where((v) {
      final status = v.visitDetails.status.toLowerCase();
      final hasApprovedProposal = v.proposalChecklist.approved;
      final hasApprovedPayment = v.payment.paymentConfirmed;
      return status == 'confirmed' || hasApprovedProposal || hasApprovedPayment;
    }).length;

    final inDiscussionCount = visits.where((v) {
      final status = v.visitDetails.status.toLowerCase();
      return status == 'pending' || status == 'follow-up' || status == 'discussion' || status == 'scheduled';
    }).length;

    double totalBillsAmount = 0.0;
    for (final b in bills) {
      totalBillsAmount += b.amount;
    }

    final winRate = totalVisits > 0 ? ((confirmedCount / totalVisits) * 100).toStringAsFixed(1) : '0.0';

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: _C.bg,
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: _C.amber,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            MediaQuery.of(context).padding.top + 20,
            isDesktop ? 32 : 16,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome & Agent Profile Banner
              _buildHeader(userName, userRole),
              const SizedBox(height: 24),

              // 2. Metric Hero Cards Strip
              _buildMetricStrip(
                totalVisits: totalVisits,
                confirmedCount: confirmedCount,
                inDiscussionCount: inDiscussionCount,
                totalBillsAmount: totalBillsAmount,
                winRate: winRate,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 28),

              // 3. Quick Action Launcher
              _buildQuickActions(context, userId, userName, userRole),
              const SizedBox(height: 32),

              // 4. Two-Column Bento Layout (Missions & Expenses)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildRecentVisitsCard(context, visits, userId, userRole),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildExpenseClaimsCard(context, bills, userId, userName),
                          const SizedBox(height: 20),
                          _buildMarketingTasksCard(context, taskProvider, userId, userRole),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildRecentVisitsCard(context, visits, userId, userRole),
                const SizedBox(height: 20),
                _buildExpenseClaimsCard(context, bills, userId, userName),
                const SizedBox(height: 20),
                _buildMarketingTasksCard(context, taskProvider, userId, userRole),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader(String userName, String role) {
    final nowStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _C.amber.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Field Marketing HQ",
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      "OUTREACH & DEMOS",
                      style: TextStyle(
                        color: _C.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Welcome, $userName • $nowStr",
                style: const TextStyle(color: _C.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh_rounded, color: _C.textMuted),
          tooltip: "Sync Pipeline & Visits",
        ),
      ],
    );
  }

  // ═══════════════════ METRIC STRIP ═══════════════════
  Widget _buildMetricStrip({
    required int totalVisits,
    required int confirmedCount,
    required int inDiscussionCount,
    required double totalBillsAmount,
    required String winRate,
    required bool isDesktop,
  }) {
    final items = [
      _MetricData(
        title: "School Visits",
        value: "$totalVisits",
        subtext: "Logged missions",
        icon: Icons.school_rounded,
        color: _C.cyan,
      ),
      _MetricData(
        title: "Confirmed Schools",
        value: "$confirmedCount",
        subtext: "$winRate% conversion rate",
        icon: Icons.verified_rounded,
        color: _C.emerald,
      ),
      _MetricData(
        title: "Active Pipeline",
        value: "$inDiscussionCount",
        subtext: "In-discussion demos",
        icon: Icons.timelapse_rounded,
        color: _C.amber,
      ),
      _MetricData(
        title: "Travel Expenses",
        value: "₹${NumberFormat('#,##,###').format(totalBillsAmount.toInt())}",
        subtext: "Claims filed",
        icon: Icons.receipt_long_rounded,
        color: _C.purple,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: items.map((m) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildMetricCard(m),
        ))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: items.map((m) => _buildMetricCard(m)).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.title,
                style: const TextStyle(
                  color: _C.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.value,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.subtext,
                style: TextStyle(color: m.color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ QUICK ACTIONS ═══════════════════
  Widget _buildQuickActions(
    BuildContext context,
    String userId,
    String userName,
    String userRole,
  ) {
    final actions = [
      _ActionDef(
        title: "Log School Visit",
        subtitle: "Demo / Principal Pitch",
        icon: Icons.add_location_alt_rounded,
        color: _C.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddVisitPage(
                userId: userId,
                name: userName,
                role: userRole,
              ),
            ),
          ).then((_) => _refreshData());
        },
      ),
      _ActionDef(
        title: "My Visits & Demos",
        subtitle: "Browse All Records",
        icon: Icons.list_alt_rounded,
        color: _C.cyan,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SchoolVisitListPage(
                userId: userId,
                name: userName,
                role: userRole,
              ),
            ),
          ).then((_) => _refreshData());
        },
      ),
      _ActionDef(
        title: "Submit Expense Bill",
        subtitle: "Travel, Fuel, Stay",
        icon: Icons.post_add_rounded,
        color: _C.emerald,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddBillPage(
                userId: userId,
                userName: userName,
              ),
            ),
          ).then((_) => _refreshData());
        },
      ),
      _ActionDef(
        title: "My Expense Claims",
        subtitle: "Claims & Receipts",
        icon: Icons.account_balance_wallet_rounded,
        color: _C.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MyBillsPage(
                userId: userId,
                userName: userName,
              ),
            ),
          ).then((_) => _refreshData());
        },
      ),
      _ActionDef(
        title: "Tele-Outreach Leads",
        subtitle: "Call Logs & Pipeline",
        icon: Icons.phone_in_talk_rounded,
        color: _C.rose,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TeleMarketingPage(),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "FIELD OPERATIONS & ACTIONS",
          style: TextStyle(
            color: _C.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions.map((a) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: a.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 175,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: a.color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(a.icon, color: a.color, size: 20),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            a.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.subtitle,
                            style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ RECENT FIELD VISITS CARD ═══════════════════
  Widget _buildRecentVisitsCard(
    BuildContext context,
    List<SchoolVisit> visits,
    String userId,
    String userRole,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.explore_rounded, color: _C.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Recent School Demos & Visits",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SchoolVisitListPage(
                        userId: userId,
                        name: auth.name ?? '',
                        role: userRole,
                      ),
                    ),
                  ).then((_) => _refreshData());
                },
                child: const Text("View All", style: TextStyle(color: _C.amber, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (visits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  children: [
                    Icon(Icons.location_city_rounded, size: 40, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 10),
                    const Text("No school visits recorded yet.", style: TextStyle(color: _C.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final auth = context.read<AuthProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddVisitPage(
                              userId: userId,
                              name: auth.name ?? '',
                              role: userRole,
                            ),
                          ),
                        ).then((_) => _refreshData());
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Log First Visit", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visits.take(6).length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
              itemBuilder: (context, index) {
                final visit = visits[index];
                final schoolName = visit.schoolProfile.name.isNotEmpty
                    ? visit.schoolProfile.name
                    : 'School Visit #${index + 1}';
                final city = visit.schoolProfile.city.isNotEmpty
                    ? visit.schoolProfile.city
                    : (visit.schoolProfile.state.isNotEmpty ? visit.schoolProfile.state : 'Location N/A');
                final state = visit.schoolProfile.state;
                final contactPerson = visit.contactPersons.isNotEmpty
                    ? visit.contactPersons.first.name
                    : 'Principal / Coordinator';

                final isConfirmed = (visit.visitDetails.status.toLowerCase() == 'confirmed') ||
                    visit.proposalChecklist.approved ||
                    visit.payment.paymentConfirmed;

                final statusColor = isConfirmed ? _C.emerald : _C.amber;
                final statusLabel = isConfirmed ? 'Confirmed' : visit.visitDetails.status;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisitDetailsPage(
                            visit: visit,
                            userId: userId,
                            role: userRole,
                          ),
                        ),
                      ).then((_) => _refreshData());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.school_outlined, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schoolName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$city, $state • Contact: $contactPerson",
                                  style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, color: _C.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════ EXPENSE CLAIMS CARD ═══════════════════
  Widget _buildExpenseClaimsCard(
    BuildContext context,
    List<Bill> bills,
    String userId,
    String userName,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_rounded, color: _C.emerald, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Expense Claims",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: _C.emerald, size: 20),
                tooltip: "New Claim",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBillPage(
                        userId: userId,
                        userName: userName,
                      ),
                    ),
                  ).then((_) => _refreshData());
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No expense bills filed yet.",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.take(4).length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 12),
              itemBuilder: (context, index) {
                final bill = bills[index];
                final amount = bill.amount.toStringAsFixed(0);
                final type = bill.type;
                final desc = bill.description.isNotEmpty ? bill.description : 'Field claim';
                final status = bill.status;

                Color statusColor;
                if (status.toLowerCase() == 'approved') {
                  statusColor = _C.emerald;
                } else if (status.toLowerCase() == 'rejected') {
                  statusColor = _C.rose;
                } else {
                  statusColor = _C.amber;
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        type == 'Travel' ? Icons.directions_car_rounded : Icons.local_dining_rounded,
                        color: _C.emerald,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(type, style: const TextStyle(color: _C.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹$amount",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ═══════════════════ MARKETING TASKS & UPDATES CARD ═══════════════════
  Widget _buildMarketingTasksCard(
    BuildContext context,
    TaskProvider taskProvider,
    String userId,
    String userRole,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: _C.purple, size: 20),
              SizedBox(width: 8),
              Text(
                "Field Directives & Tasks",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<TaskModel>>(
            stream: taskProvider.getTasksForUserStream(userId, userRole),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _C.purple),
                  ),
                );
              }

              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No tasks currently assigned to Marketing.",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  Color priorityColor;
                  switch (task.priority) {
                    case 'High':
                      priorityColor = _C.rose;
                      break;
                    case 'Low':
                      priorityColor = _C.emerald;
                      break;
                    default:
                      priorityColor = _C.amber;
                  }

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => TaskWorkThreadSheet.show(context, task),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: priorityColor, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Status: ${task.status} • Tap to update",
                                    style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chat_bubble_outline_rounded, color: _C.cyan, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  _MetricData({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });
}

class _ActionDef {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionDef({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
