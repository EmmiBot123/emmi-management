import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import 'Assembly/School_assembly_page.dart';
import 'Installation/installation_team_page.dart';

/// Combined Operations page merging Assembly + Installation
/// with a segmented toggle matching the Sales page style.
class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0 = Assembly, 1 = Installation
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
    final topPad = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;

    // Individual role users bypass the toggle
    if (userRole == "ASSEMBLY_TEAM") {
      return const SchoolAssemblyPage();
    }
    if (userRole == "INSTALLATION_TEAM") {
      return const InstallationTeamPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ═══════════ HERO HEADER ═══════════
          FadeTransition(
            opacity: _heroAnim,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPad + 52,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative circles
                  Positioned(
                    right: -35,
                    top: -50,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -25,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 50,
                    bottom: 15,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.precision_manufacturing_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Operations",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Assembly & Installation teams",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Segmented Toggle ──
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            _buildSegment(
                              "Assembly",
                              Icons.build_rounded,
                              0,
                              width,
                            ),
                            _buildSegment(
                              "Installation",
                              Icons.engineering_rounded,
                              1,
                              width,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ═══════════ CONTENT ═══════════
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_tabIndex),
                child: _tabIndex == 0
                    ? const SchoolAssemblyPage()
                    : const InstallationTeamPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
      String label, IconData icon, int index, double screenWidth) {
    final isActive = _tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFF0D7377)
                    : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF0D7377)
                        : Colors.white.withOpacity(0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
