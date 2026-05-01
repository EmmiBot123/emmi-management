import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/User_provider.dart';
import 'markerting/SchoolVisit/school_visit_list_page.dart';
import 'markerting/admin_to_marketing.dart';
import 'markerting/marketing_page.dart';
import 'TeleMarketing/TeleMarketing.dart';
import 'TeleMarketing/admin_to_telemarketing.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final id = auth.userId ?? "";
      if (id.isNotEmpty) {
        context.read<UserProvider>().loadMembers(id);
      }
    });
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

  Widget _getContent() {
    final auth = context.watch<AuthProvider>();
    final userRole = auth.role!;
    final id = auth.userId!;
    final name = auth.name!;

    if (_tabIndex == 0) {
      if (userRole == "MARKETING") {
        return SchoolVisitListPage(userId: id, name: name, role: userRole);
      } else if (userRole == "SUPER_ADMIN") {
        return const AdminToMarketing();
      }
      return const MarketingPage();
    } else {
      if (userRole == "TELE_MARKETING") {
        return SchoolVisitListPage(userId: id, name: name, role: userRole);
      } else if (userRole == "SUPER_ADMIN") {
        return const AdminToTelemarketing();
      }
      return const TeleMarketingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userRole = auth.role!;
    final topPad = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;

    // Individual role users bypass the toggle
    if (userRole == "MARKETING") {
      return SchoolVisitListPage(
          userId: auth.userId!, name: auth.name!, role: userRole);
    }
    if (userRole == "TELE_MARKETING") {
      return SchoolVisitListPage(
          userId: auth.userId!, name: auth.name!, role: userRole);
    }

    final prov = context.watch<UserProvider>();
    final marketingCount = prov.marketing.length;
    final teleCount = prov.teleMarketing.length;

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
                  colors: [Color(0xFF1B1464), Color(0xFF6C63FF)],
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
                    right: -40,
                    top: -60,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -30,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    bottom: 10,
                    child: Container(
                      width: 40,
                      height: 40,
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
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sales Hub",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Manage your sales teams",
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

                      // ── Stats Row ──
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.campaign_rounded,
                            label: "Marketing",
                            count: marketingCount,
                            color: const Color(0xFFFFBB55),
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.phone_in_talk_rounded,
                            label: "Tele Marketing",
                            count: teleCount,
                            color: const Color(0xFF00D4AA),
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: Icons.people_rounded,
                            label: "Total",
                            count: marketingCount + teleCount,
                            color: Colors.white,
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
                              "Marketing",
                              Icons.campaign_rounded,
                              0,
                              width,
                            ),
                            _buildSegment(
                              "Tele Marketing",
                              Icons.phone_in_talk_rounded,
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
                child: _getContent(),
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
    final isSmall = screenWidth < 400;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isSmall ? 8 : 12,
          ),
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
                    ? const Color(0xFF1B1464)
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
                        ? const Color(0xFF1B1464)
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

// ═══════════════════ STAT CHIP ═══════════════════
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return Text(
                  val.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
