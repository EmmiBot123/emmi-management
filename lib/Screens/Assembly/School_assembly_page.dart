import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import 'assembly_page.dart';
import '../GenericTeamPage.dart';
import '../SuperAdmin/ProductManagementPage/ProductManagementPage.dart';

class SchoolAssemblyPage extends StatefulWidget {
  const SchoolAssemblyPage({
    super.key,
  });

  @override
  State<SchoolAssemblyPage> createState() => _SchoolAssemblyPageState();
}

class _SchoolAssemblyPageState extends State<SchoolAssemblyPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SchoolVisitProvider>().loadAssemblyVisits(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();

    return WillPopScope(
      onWillPop: () async {
        provider.clear();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Assembly Queue",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
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
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.textSecondary),
              tooltip: "Product Management",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductManagementPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.people_outline, color: AppColors.textSecondary),
              tooltip: "View Team Members",
              onPressed: () {
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
            const SizedBox(width: 8),
          ],
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : provider.assemblyVisits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.precision_manufacturing_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          "No schools in assembly queue.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: provider.assemblyVisits.length,
                    itemBuilder: (_, index) {
                      final visit = provider.assemblyVisits[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisitDetailsPage(
                                visit: visit,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.surfaceLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      visit.schoolProfile.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "In Assembly",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: AppColors.surfaceLight, height: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildInfoItem(Icons.person_outline, visit.assignedUserName?.isNotEmpty == true ? visit.assignedUserName! : visit.createdByUserName),
                                  const SizedBox(width: 24),
                                  _buildInfoItem(Icons.admin_panel_settings_outlined, visit.adminName ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      visit.schoolProfile.address,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
