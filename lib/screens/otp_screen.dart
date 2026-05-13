import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'home_screen.dart';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'city_selection_screen.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_config.dart';
import '../widgets/reward_popup.dart';
import '../services/fcm_service.dart';
import '../services/user_helper.dart';
class OtpScreen extends StatefulWidget {
  final AuthService authService;
  final String phone; // ✅ ADD THIS

  const OtpScreen({
    super.key,
    required this.authService,
    required this.phone, // ✅ ADD THIS
  });

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
  String normalizePhone(String phone) {
  // remove everything except digits
  String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

  // remove country code (India)
  if (cleaned.startsWith("91") && cleaned.length > 10) {
    cleaned = cleaned.substring(cleaned.length - 10);
  }

  return cleaned;
}

void verifyOtp() async {
  if (otpCode.length < 6) {
    shakeController.forward(from: 0);
    return;
  }

  setState(() {
    loading = true;
  });

  bool showRewardPopup = false;
  int rewardAmount = 0;
  /// 🔥 APPLE REVIEW OTP BYPASS
if (widget.phone == "9999999999" &&
    otpCode == "123456") {

  final phone = "9999999999";

  await FirebaseAuth.instance.signInAnonymously();

  await UserHelper.setPhone(phone);

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const MainScreen(),
    ),
    (route) => false,
  );

  return;
}

  try {
    /// 🔥 STEP 1: VERIFY OTP
    await widget.authService.verifyOtp(widget.phone, otpCode);

    /// 🔥 STEP 2: NORMALIZE PHONE
    final phone = normalizePhone(widget.phone);

    /// 🔥 STEP 3: FIREBASE AUTH (for rules)
    await FirebaseAuth.instance.signInAnonymously();

    /// 🔥 STEP 4: SAVE PHONE (UPDATED)
    await UserHelper.setPhone(phone);

    final branch = TenantConfig.branchCode;
    const int welcomeReward = 100;

    final userRef = FirebaseFirestore.instance
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(phone);

    final userSnap = await userRef.get();

    /// 🆕 NEW USER
    if (!userSnap.exists) {
      await userRef.set({
        "phone": phone,
        "name": "",
        "branch": branch,
        "createdAt": FieldValue.serverTimestamp(),
        "firstLogin": FieldValue.serverTimestamp(),
        "creditBalance": welcomeReward,
        "rewardGiven": true,
      });

      showRewardPopup = true;
      rewardAmount = welcomeReward;

      /// 🔥 CREATE CREDIT NOTE
      await FirebaseFirestore.instance
          .collection("products")
          .doc(branch)
          .collection("creditNotes")
          .add({
        "Name": "Customer",
        "mobileNumber": phone,
        "amount": welcomeReward,
        "CreditUsed": 0,
        "Balance": welcomeReward,
        "Comment": "App Signup Reward 🎉",
        "status": "active",
        "source": "app_signup",
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": "app",
      });
    }

    /// 🔁 EXISTING USER
    else {
      final data = userSnap.data();
      final rewardGiven = data?["rewardGiven"] == true;

      /// 🎁 FIRST LOGIN (MIGRATED USER)
      if (!rewardGiven) {
        await userRef.set({
          "firstLogin": FieldValue.serverTimestamp(),
          "creditBalance": FieldValue.increment(welcomeReward),
          "rewardGiven": true,
        }, SetOptions(merge: true));

        showRewardPopup = true;
        rewardAmount = welcomeReward;

        /// 🔥 CHECK CREDIT NOTE
        final creditQuery = await FirebaseFirestore.instance
            .collection("products")
            .doc(branch)
            .collection("creditNotes")
            .where("mobileNumber", isEqualTo: phone)
            .limit(1)
            .get();

        if (creditQuery.docs.isNotEmpty) {
          final docRef = creditQuery.docs.first.reference;
          final existing = creditQuery.docs.first.data();

          final newAmount = (existing["amount"] ?? 0) + welcomeReward;
          final newBalance = (existing["Balance"] ?? 0) + welcomeReward;

          await docRef.update({
            "amount": newAmount,
            "Balance": newBalance,
            "Comment": "Updated: App Signup Reward 🎉",
            "updatedAt": FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance
              .collection("products")
              .doc(branch)
              .collection("creditNotes")
              .add({
            "Name": data?["name"] ?? "Customer",
            "mobileNumber": phone,
            "amount": welcomeReward,
            "CreditUsed": 0,
            "Balance": welcomeReward,
            "Comment": "App Signup Reward 🎉",
            "status": "active",
            "source": "app_signup",
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": "app",
          });
        }
      }

      /// 🔁 NORMAL LOGIN
      else {
        await userRef.set({
          "lastLogin": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    if (!mounted) return;

    /// 🔥 FCM SETUP
    await FCMService.setupFCM();

    /// 🔥 LOAD HOME
    final homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.loadHomeData();

    if (!mounted) return;

    /// 🔥 NAVIGATE
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
      (route) => false,
    );

    /// 🎉 POPUP
    if (showRewardPopup) {
      Future.delayed(const Duration(milliseconds: 400), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => RewardPopup(amount: rewardAmount),
        );
      });
    }

  } catch (e) {
    if (!mounted) return;

    shakeController.forward(from: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid OTP")),
    );
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
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
                         onPressed: () async {
  startTimer();
  await widget.authService.sendOtp(
    phone: widget.phone,
    codeSent: () {},
  );
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