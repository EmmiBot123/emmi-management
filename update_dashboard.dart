import 'dart:io';

void main() {
  final file = File('lib/Screens/SuperAdmin/super_admin_page.dart');
  var content = file.readAsStringSync();

  // 1. Imports
  content = content.replaceFirst(
    "import 'package:flutter/material.dart';",
    "import 'dart:ui';\nimport 'dart:math' as math;\nimport 'package:flutter/material.dart';"
  );

  // 2. Palette
  content = content.replaceFirst(
    '''class _Palette {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const accentAlt = Color(0xFF00D4AA);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFBB55);
  static const success = Color(0xFF00D4AA);
  static const info = Color(0xFF5B8DEF);
}''',
    '''class _Palette {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const surfaceLight = Color(0xFF27272A);
  static const accent = Color(0xFF38BDF8);
  static const accentAlt = Color(0xFF818CF8);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF0EA5E9);
}'''
  );

  // 3. Variables
  content = content.replaceFirst(
    '''  late AnimationController _pulseController;''',
    '''  late AnimationController _pulseController;\n  late AnimationController _bgAnimationController;'''
  );

  // 4. initState
  content = content.replaceFirst(
    '''    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadAllMetrics();''',
    '''    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _loadAllMetrics();'''
  );

  // 5. dispose
  content = content.replaceFirst(
    '''    _pulseController.dispose();
    super.dispose();''',
    '''    _pulseController.dispose();
    _bgAnimationController.dispose();
    super.dispose();'''
  );

  // 6. Build method start
  content = content.replaceFirst(
    '''    return Container(
      color: _Palette.bg,
      child: _isLoading
          ? _buildLoader()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(''',
    '''    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          // Dynamic Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DynamicMeshGradientPainter(_bgAnimationController.value),
                );
              },
            ),
          ),
          // Glass Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: _Palette.bg.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: _isLoading
                ? _buildLoader()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator('''
  );

  // 7. Build method end
  content = content.replaceFirst(
    '''                    _buildTeamSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }''',
    '''                    _buildTeamSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }'''
  );

  // 8. _buildHeader start
  content = content.replaceFirst(
    '''    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(''',
    '''    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Stack('''
  );

  // 9. _buildHeader end
  content = content.replaceFirst(
    '''                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ METRIC STRIP ═══════════════════''',
    '''                ),
              ),
            ],
          ),
        ],
      ),
            ),
          ),
        ),
    );
  }

  // ═══════════════════ METRIC STRIP ═══════════════════'''
  );

  // 10. Change all color: _Palette.surface to color: _Palette.surface.withValues(alpha: 0.4)
  // Be careful not to replace it when it's just `_Palette.surface` like in dropdownColor or backgroundColor if we only want container translucency,
  // but using RegExp to find `color: _Palette.surface,` with any whitespace before it.
  content = content.replaceAll(
    RegExp(r'color:\s*_Palette\.surface,'),
    'color: _Palette.surface.withValues(alpha: 0.4),'
  );

  // Add the Painter class at the end
  content += '''

// ═══════════════════ ANIMATED BACKGROUND PAINTER ═══════════════════
class _DynamicMeshGradientPainter extends CustomPainter {
  final double animationValue;

  _DynamicMeshGradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF09090B));

    final centerX1 = size.width * (0.2 + 0.3 * math.sin(animationValue * math.pi * 2));
    final centerY1 = size.height * (0.2 + 0.3 * math.cos(animationValue * math.pi * 2));

    final centerX2 = size.width * (0.8 + 0.2 * math.cos(animationValue * math.pi * 2));
    final centerY2 = size.height * (0.7 + 0.2 * math.sin(animationValue * math.pi * 2));

    final centerX3 = size.width * (0.5 + 0.3 * math.sin(animationValue * math.pi * 2 + math.pi));
    final centerY3 = size.height * (0.9 + 0.1 * math.cos(animationValue * math.pi * 2));

    _drawOrb(canvas, Offset(centerX1, centerY1), const Color(0xFF0284C7).withValues(alpha: 0.5), size.width * 0.4);
    _drawOrb(canvas, Offset(centerX2, centerY2), const Color(0xFF4338CA).withValues(alpha: 0.4), size.width * 0.5);
    _drawOrb(canvas, Offset(centerX3, centerY3), const Color(0xFF38BDF8).withValues(alpha: 0.3), size.width * 0.3);
    
    _drawGrid(canvas, size);
  }

  void _drawOrb(Canvas canvas, Offset center, Color color, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 50.0;
    final offsetX = (animationValue * spacing) % spacing;
    final offsetY = (animationValue * spacing * 0.5) % spacing;

    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      canvas.drawLine(Offset(i + offsetX, 0), Offset(i + offsetX, size.height), paint);
    }
    for (double i = -spacing; i < size.height + spacing; i += spacing) {
      canvas.drawLine(Offset(0, i + offsetY), Offset(size.width, i + offsetY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicMeshGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
''';

  file.writeAsStringSync(content);
  print('Successfully updated SuperAdminPage.dart');
}
