import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'home_screen.dart';
import 'main_screen.dart';
class OtpScreen extends StatefulWidget {
  final AuthService authService;

  const OtpScreen({super.key, required this.authService});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {

  String otpCode = "";
  bool loading = false;

  int seconds = 30;
  Timer? timer;

  late AnimationController shakeController;

  @override
  void initState() {
    super.initState();
    startTimer();

    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void startTimer() {
    seconds = 30;

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (seconds == 0) {
          timer.cancel();
        } else {
          setState(() {
            seconds--;
          });
        }
      },
    );
  }

  void verifyOtp() async {

    if (otpCode.length < 6) {
      shakeController.forward(from: 0);
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      await widget.authService.verifyOtp(otpCode);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
        (route) => false,
      );

    } catch (e) {

      shakeController.forward(from: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );

    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(

      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,

      body: SafeArea(

        child: SingleChildScrollView(

          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          child: ConstrainedBox(

            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 40,
            ),

            child: Padding(

              padding: const EdgeInsets.symmetric(horizontal: 28),

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

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
                      Icons.sms_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Enter the 6 digit code sent to your phone",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 40),

                  /// OTP BOXES
                  AnimatedBuilder(
                    animation: shakeController,
                    builder: (context, child) {

                      double offset =
                          (shakeController.value * 10) *
                          (shakeController.value % 2 == 0 ? 1 : -1);

                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );

                    },
                    child: Pinput(
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      onCompleted: (value) {
                        otpCode = value;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// VERIFY BUTTON
                  GestureDetector(

                    onTap: loading ? null : verifyOtp,

                    child: Container(

                      height: 55,

                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: Center(

                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Verify OTP →",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// RESEND TIMER
                  seconds == 0
                      ? TextButton(
                          onPressed: () {
                            startTimer();
                          },
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          "Resend in $seconds s",
                          style:
                              const TextStyle(color: Colors.black54),
                        ),

                  const SizedBox(height: 40),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}