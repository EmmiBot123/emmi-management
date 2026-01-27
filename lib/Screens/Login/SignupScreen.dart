import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Providers/AuthProvider.dart';
import '../../Services/Auth_service.dart';

class SignupScreenLight extends StatefulWidget {
  const SignupScreenLight({super.key});

  @override
  State<SignupScreenLight> createState() => _SignupScreenLightState();
}

class _SignupScreenLightState extends State<SignupScreenLight> {
  static const Color _textPrimary = Color(0xFF2D3436);
  static const Color _textSecondary = Color(0xFF636E72);
  static const Color _primaryAccent = Color(0xFF0984E3);
  static const Color _inputFill = Color(0xFFFDFDFD);

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  bool step2 = false;
  bool loading = false;

  final service = AuthService();

  Future<void> checkEmail() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter email")));
      return;
    }

    setState(() => loading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final res = await service.verifyEmailRequest(
        email: emailController.text.trim(),
        authProvider: authProvider,
      );

      if (res == "Please verify your email.") {
        setState(() => step2 = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Invitation found. Enter OTP & details to complete registration")),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.toString())));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  Future<void> completeRegistration() async {
    if (otpController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await service.completeRegistration(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        authProvider: authProvider,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration completed successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFEAF2F8),
                  Color(0xFFF8F9FA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.2, 0.8],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: isWeb ? 420 : double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withOpacity(0.65),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                  ],
                  border: Border.all(
                      color: Colors.white.withOpacity(0.8), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 28,
                              color: _textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step2
                                ? "Enter the OTP sent by Admin & complete setup"
                                : "Enter your email to check invitation",
                            style: const TextStyle(
                              fontSize: 15,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _field(
                            hint: "Email address",
                            icon: Icons.email_outlined,
                            controller: emailController,
                          ),
                          if (step2) ...[
                            const SizedBox(height: 16),
                            _field(
                              hint: "OTP Code",
                              icon: Icons.verified_outlined,
                              controller: otpController,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              hint: "Phone Number",
                              icon: Icons.phone_outlined,
                              controller: phoneController,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              hint: "Password",
                              icon: Icons.lock_outline,
                              controller: passwordController,
                              isObscure: true,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              hint: "Confirm Password",
                              icon: Icons.lock_outline_rounded,
                              controller: confirmPasswordController,
                              isObscure: true,
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: _primaryAccent,
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: loading
                                  ? null
                                  : step2
                                      ? completeRegistration
                                      : checkEmail,
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : Text(step2
                                      ? "Complete Registration"
                                      : "Verify Invitation"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(
                                  color: _primaryAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _field({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: _textSecondary),
        filled: true,
        fillColor: _inputFill,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryAccent, width: 1.5),
        ),
      ),
    );
  }
}
