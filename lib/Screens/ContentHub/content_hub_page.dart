import 'dart:ui';
import 'package:flutter/material.dart';
import 'course_list_tab.dart';
import 'project_list_tab.dart';

class ContentHubPage extends StatefulWidget {
  const ContentHubPage({super.key});

  @override
  State<ContentHubPage> createState() => _ContentHubPageState();
}

class _ContentHubPageState extends State<ContentHubPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Obsidian
      body: Stack(
        children: [
          // 1. Animated Mesh Gradient Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlob(300, const Color(0xFF38BDF8).withOpacity(0.15)), // Blue
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildBlob(400, const Color(0xFF9333EA).withOpacity(0.15)), // Purple
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                const Padding(
                  padding: EdgeInsets.only(left: 64, right: 24, top: 16, bottom: 16),
                  child: Text(
                    "CONTENT HUB",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                // Fluid Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      CourseListTab(),
                      ProjectListTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Glowing Obsidian Floating Dock
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDockItem(0, Icons.school_rounded, "Courses", const Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        _buildDockItem(1, Icons.rocket_launch_rounded, "Projects", const Color(0xFF9333EA)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label, Color accentColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.white.withOpacity(0.35), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.35),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
