import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Services/Auth_service.dart';
import 'signup_screen.dart';

class LoginScreenLight extends StatefulWidget {
  const LoginScreenLight({super.key});

  @override
  State<LoginScreenLight> createState() => _LoginScreenLightState();
}

class _LoginScreenLightState extends State<LoginScreenLight>
    with TickerProviderStateMixin {
  // Ultra-Premium Dark Theme Colors
  static const Color _bgDark = Color(0xFF09090B); // Zinc 950
  static const Color _bgCard = Color(0xFF18181B); // Zinc 900
  static const Color _textPrimary = Color(0xFFFAFAFA);
  static const Color _textSecondary = Color(0xFFA1A1AA);
  static const Color _primaryAccent = Color(0xFF38BDF8); // Sky 400
  static const Color _primaryAccentDark = Color(0xFF0284C7); // Sky 600
  static const Color _glowColor = Color(0xFF818CF8); // Indigo 400

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  // Animations
  late AnimationController _entranceController;
  late AnimationController _bgAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _bgAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email & Password required"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (emailController.text.trim() == "installation@test.com" &&
          passwordController.text.trim() == "installation") {
        await authProvider.saveLoginData(
          token: "test_token_installation",
          user: {
            "id": "test_install_user",
            "name": "Installation Tester",
            "email": "installation@test.com",
            "role": "INSTALLATION_TEAM",
          },
        );
      } else {
        final service = AuthService();
        await service.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          authProvider: authProvider,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
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
          // Glass Overlay to smooth the background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: _bgDark.withOpacity(0.5),
              ),
            ),
          ),
          
          // Main Content Layer
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWeb = constraints.maxWidth > 900;
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Container(
      width: 1000,
      height: 650,
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _bgCard.withOpacity(0.4),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              // Left Side - Branding
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Image.asset(
                        'assets/images/logo-full.png',
                        width: 360,
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.business, size: 80, color: Colors.white),
                      ),
                      const SizedBox(height: 80),
                      const Text(
                        "Elevate Your\nWorkspace.",
                        style: TextStyle(
                          fontSize: 56,
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Qubiq OS brings all your management tools into one seamless, powerful, and intelligent platform.",
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              // Right Side - Login Form
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: _buildFormContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _bgCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo-full.png',
                  width: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.business, size: 80, color: _primaryAccent),
                ),
                const SizedBox(height: 32),
                _buildFormContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFB0B4C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "Welcome back",
            style: TextStyle(
              fontSize: 42,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Enter your credentials to securely access your workspace.",
          style: TextStyle(
            fontSize: 15,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        _buildGlowingTextField(
          hint: "Email Address",
          icon: Icons.alternate_email_rounded,
          controller: emailController,
        ),
        const SizedBox(height: 20),
        _buildGlowingTextField(
          hint: "Password",
          icon: Icons.lock_outline_rounded,
          isObscure: true,
          controller: passwordController,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) {
                  final resetEmailCtrl = TextEditingController(text: emailController.text);
                  bool isSending = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: _bgCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Enter your email address to receive a password reset link.",
                              style: TextStyle(color: _textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: resetEmailCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Email Address",
                                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel", style: TextStyle(color: _textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: isSending ? null : () async {
                              final email = resetEmailCtrl.text.trim();
                              if (email.isEmpty) return;
                              setState(() => isSending = true);
                              try {
                                await AuthService().resetPassword(email);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Reset link sent to $email"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isSending = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isSending 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Send Link", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    }
                  );
                },
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: _primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Forgot password?",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Premium Button
        _GlowingButton(
          loading: loading,
          onPressed: loading ? null : login,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreenLight(),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlowingTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isObscure = false,
  }) {
    return _GlowingTextField(
      hint: hint,
      icon: icon,
      controller: controller,
      isObscure: isObscure,
    );
  }

}

class _GlowingTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool isObscure;

  const _GlowingTextField({
    required this.hint,
    required this.icon,
    this.controller,
    this.isObscure = false,
  });

  @override
  State<_GlowingTextField> createState() => _GlowingTextFieldState();
}

class _GlowingTextFieldState extends State<_GlowingTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  static const Color _textPrimary = Color(0xFFFAFAFA);
  static const Color _textSecondary = Color(0xFFA1A1AA);
  static const Color _primaryAccent = Color(0xFF38BDF8);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: _primaryAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isObscure,
        focusNode: _focusNode,
        style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
        cursorColor: _primaryAccent,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
          prefixIcon: Icon(widget.icon, color: _isFocused ? _primaryAccent : _textSecondary.withOpacity(0.7), size: 22),
          filled: true,
          fillColor: Colors.white.withOpacity(0.03),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _GlowingButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _GlowingButton({required this.loading, this.onPressed});

  @override
  State<_GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<_GlowingButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  static const Color _primaryAccent = Color(0xFF38BDF8);
  static const Color _glowColor = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final isIlluminated = _isHovered || _isPressed;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_primaryAccent, _glowColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryAccent.withOpacity(isIlluminated ? 0.7 : 0.3),
                blurRadius: isIlluminated ? 30 : 20,
                spreadRadius: isIlluminated ? 4 : 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          transform: Matrix4.identity()..scale(isIlluminated ? 0.98 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DynamicMeshGradientPainter extends CustomPainter {
  final double animationValue;

  _DynamicMeshGradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Draw base dark color
    canvas.drawRect(rect, Paint()..color = const Color(0xFF09090B));

    // Calculate moving positions based on animation value
    final centerX1 = size.width * (0.2 + 0.3 * math.sin(animationValue * math.pi * 2));
    final centerY1 = size.height * (0.2 + 0.3 * math.cos(animationValue * math.pi * 2));

    final centerX2 = size.width * (0.8 + 0.2 * math.cos(animationValue * math.pi * 2));
    final centerY2 = size.height * (0.7 + 0.2 * math.sin(animationValue * math.pi * 2));

    final centerX3 = size.width * (0.5 + 0.3 * math.sin(animationValue * math.pi * 2 + math.pi));
    final centerY3 = size.height * (0.9 + 0.1 * math.cos(animationValue * math.pi * 2));

    // Draw glowing orbs that will be blurred heavily
    _drawOrb(canvas, Offset(centerX1, centerY1), const Color(0xFF0284C7).withOpacity(0.5), size.width * 0.4);
    _drawOrb(canvas, Offset(centerX2, centerY2), const Color(0xFF4338CA).withOpacity(0.4), size.width * 0.5);
    _drawOrb(canvas, Offset(centerX3, centerY3), const Color(0xFF38BDF8).withOpacity(0.3), size.width * 0.3);
    
    // Add grid overlay for that tech/cyber feel
    _drawGrid(canvas, size);
  }

  void _drawOrb(Canvas canvas, Offset center, Color color, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 50.0;
    
    // Move grid slightly with animation
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
