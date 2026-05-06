import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import 'School_account_page.dart';
import 'all_bills_page.dart';
import 'payment_page.dart';

class AccountsDashboard extends StatefulWidget {
  const AccountsDashboard({super.key});

  @override
  State<AccountsDashboard> createState() => _AccountsDashboardState();
}

class _AccountsDashboardState extends State<AccountsDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SchoolVisitProvider>().loadPaymentVisits());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialStats(provider),
                  const SizedBox(height: 24),
                  _buildBentoGrid(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader("PENDING CLEARANCE", Icons.pending_actions_outlined),
                  const SizedBox(height: 16),
                  _buildPendingList(provider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent.withOpacity(0.15), AppColors.bg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: const Text(
          "Finance Control",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialStats(SchoolVisitProvider provider) {
    double pendingAmount = 0;
    double receivedAmount = 0;
    
    for (var v in provider.paymentVisits) {
      if (v.payment.paymentConfirmed) {
        receivedAmount += v.payment.amount;
      } else {
        pendingAmount += v.payment.amount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL PENDING", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  "₹${pendingAmount.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.surfaceLight),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL RECEIVED", style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  "₹${receivedAmount.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "School Payments",
                "Verify collections",
                Icons.account_balance_outlined,
                Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolVisitListPageAccounts())),
                height: 180,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "Staff Bills",
                "Approve expenses",
                Icons.receipt_long_outlined,
                Colors.purpleAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllBillsPage())),
                height: 180,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoBox(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {double height = 120}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingList(SchoolVisitProvider provider) {
    final pending = provider.paymentVisits.where((v) => !v.payment.paymentConfirmed).take(5).toList();

    if (pending.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text("No pending payments", style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Column(
      children: pending.map((v) => _buildPaymentCard(v)).toList(),
    );
  }

  Widget _buildPaymentCard(dynamic visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.schoolProfile.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "By: ${visit.assignedUserName ?? visit.createdByUserName ?? 'Staff'}",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${visit.payment.amount.toStringAsFixed(0)}",
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                "PENDING",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
