import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'otp_screen.dart';
import '../services/tenant_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final phoneController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;

  void sendOtp() async {

    final phone = phoneController.text.trim();

    /// ✅ VALIDATION
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid mobile number")),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      await authService.sendOtp(
        phone: phone,
        codeSent: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                authService: authService,
                phone: phone,
              ),
            ),
          );

        },
      );
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP")),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(

            children: [

              const SizedBox(height: 60),

              /// ICON
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 38,
                ),
              ),

              const SizedBox(height: 30),

              /// TITLE
              Text(
                "Welcome to ${TenantConfig.appName}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Enter your phone number to continue your premium fashion journey.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              /// CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 25,
                      offset: const Offset(0,10),
                    )
                  ],
                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "MOBILE NUMBER",
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// PHONE FIELD
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading, // 🔥 DISABLE WHILE LOADING
                      decoration: InputDecoration(
                        hintText: "Enter mobile number",
                        filled: true,
                        fillColor: AppColors.primaryLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// OTP BUTTON
                    GestureDetector(

                      onTap: isLoading ? null : sendOtp, // 🔥 DISABLE TAP

                      child: Container(

                        height: 55,

                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(.4),
                              blurRadius: 15,
                              offset: const Offset(0,6),
                            )
                          ],
                        ),

                        child: Center(

                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Get OTP →",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                  

                    const SizedBox(height: 20),

                    

                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// CREATE ACCOUNT
             


              const Text(
                "Privacy Policy • Terms of Service",
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }
}