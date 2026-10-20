import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../widgets/reward_popup.dart';
import 'main_screen.dart';

class OtpScreen extends StatefulWidget {
  final AuthService authService;
  final String phone;

  const OtpScreen({
    super.key,
    required this.authService,
    required this.phone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin {
  String otpCode = '';
  bool loading = false;
  bool resendLoading = false;

  int seconds = 30;
  Timer? timer;

  late final AnimationController _entranceController;
  late final AnimationController _shakeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _shakeAnimation;

  static const Color _ink = Color(0xFF29221F);
  static const Color _muted = Color(0xFF8E857D);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _cream = Color(0xFFFAF8F5);
  static const Color _softGold = Color(0xFFF7F0E7);

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: -10),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10, end: 9),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 9, end: -6),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -6, end: 4),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 4, end: 0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeOut,
      ),
    );

    _entranceController.forward();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    _entranceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    timer?.cancel();

    setStateIfMounted(() {
      seconds = 30;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (activeTimer) {
      if (!mounted) {
        activeTimer.cancel();
        return;
      }

      if (seconds <= 1) {
        activeTimer.cancel();
        setState(() => seconds = 0);
      } else {
        setState(() => seconds--);
      }
    });
  }

  void setStateIfMounted(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  String _normalizePhone(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }

    return cleaned;
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (otpCode.length != 6) {
      _shakeController.forward(from: 0);
      _showMessage('Enter the complete 6-digit OTP.');
      return;
    }

    if (loading || resendLoading) return;

    setState(() => loading = true);

    var showRewardPopup = false;
    var rewardAmount = 0;

    try {
      // Apple review test flow. Keep the configured review OTP behavior.
      if (widget.phone == '9999999999' && otpCode == '123456') {
        await FirebaseAuth.instance.signInAnonymously();

        const reviewPhone = '9999999999';
        await UserHelper.setPhone(reviewPhone);

        if (!mounted) return;

        await _loadHomeAndNavigate();
        return;
      }

      // Step 1: Verify the SMS code through the existing AuthService.
      await widget.authService.verifyOtp(widget.phone, otpCode);

      // Step 2: Normalize and persist the phone identity used by this app.
      final phone = _normalizePhone(widget.phone);

      // Step 3: Preserve the app's current Firebase-auth behavior for Firestore rules.
      await FirebaseAuth.instance.signInAnonymously();
      await UserHelper.setPhone(phone);

      final branch = TenantConfig.branchCode;
      const welcomeReward = 100;

      final userRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(branch)
          .collection('users')
          .doc(phone);

      final userSnap = await userRef.get();

      if (!userSnap.exists) {
        // New customer: create profile and welcome reward.
        await userRef.set({
          'phone': phone,
          'name': '',
          'branch': branch,
          'createdAt': FieldValue.serverTimestamp(),
          'firstLogin': FieldValue.serverTimestamp(),
          'creditBalance': welcomeReward,
          'rewardGiven': true,
        });

        showRewardPopup = true;
        rewardAmount = welcomeReward;

        await FirebaseFirestore.instance
            .collection('products')
            .doc(branch)
            .collection('creditNotes')
            .add({
          'Name': 'Customer',
          'mobileNumber': phone,
          'amount': welcomeReward,
          'CreditUsed': 0,
          'Balance': welcomeReward,
          'Comment': 'App Signup Reward 🎉',
          'status': 'active',
          'source': 'app_signup',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'app',
        });
      } else {
        final data = userSnap.data();
        final rewardGiven = data?['rewardGiven'] == true;

        if (!rewardGiven) {
          await userRef.set({
            'firstLogin': FieldValue.serverTimestamp(),
            'creditBalance': FieldValue.increment(welcomeReward),
            'rewardGiven': true,
          }, SetOptions(merge: true));

          showRewardPopup = true;
          rewardAmount = welcomeReward;

          final creditQuery = await FirebaseFirestore.instance
              .collection('products')
              .doc(branch)
              .collection('creditNotes')
              .where('mobileNumber', isEqualTo: phone)
              .limit(1)
              .get();

          if (creditQuery.docs.isNotEmpty) {
            final creditDoc = creditQuery.docs.first;
            final existing = creditDoc.data();
            final oldAmount = _asNumber(existing['amount']);
            final oldBalance = _asNumber(existing['Balance']);

            await creditDoc.reference.update({
              'amount': oldAmount + welcomeReward,
              'Balance': oldBalance + welcomeReward,
              'Comment': 'Updated: App Signup Reward 🎉',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            await FirebaseFirestore.instance
                .collection('products')
                .doc(branch)
                .collection('creditNotes')
                .add({
              'Name': data?['name'] ?? 'Customer',
              'mobileNumber': phone,
              'amount': welcomeReward,
              'CreditUsed': 0,
              'Balance': welcomeReward,
              'Comment': 'App Signup Reward 🎉',
              'status': 'active',
              'source': 'app_signup',
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': 'app',
            });
          }
        } else {
          await userRef.set({
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (!mounted) return;

      await FCMService.setupFCM();
      if (!mounted) return;

      await _loadHomeAndNavigate();

      if (showRewardPopup && mounted) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => RewardPopup(amount: rewardAmount),
          );
        });
      }
    } catch (error, stackTrace) {
      debugPrint('OTP verification failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _shakeController.forward(from: 0);
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  num _asNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid-verification-code') ||
        message.contains('invalid otp') ||
        message.contains('invalid verification code')) {
      return 'That OTP is incorrect. Please check it and try again.';
    }

    if (message.contains('session-expired') ||
        message.contains('code-expired')) {
      return 'This OTP has expired. Please request a new code.';
    }

    if (message.contains('network')) {
      return 'Network issue. Check your connection and try again.';
    }

    return 'Could not verify the OTP. Please try again.';
  }

  Future<void> _resendOtp() async {
    if (seconds > 0 || resendLoading || loading) return;

    setState(() => resendLoading = true);

    try {
      await widget.authService.sendOtp(
        phone: widget.phone,
        codeSent: () {
          if (!mounted) return;
          _showMessage('A new OTP has been sent.');
        },
      );

      if (mounted) _startTimer();
    } catch (error) {
      debugPrint('OTP resend failed: $error');

      if (mounted) {
        _showMessage('Could not resend OTP. Please try again.');
      }
    } finally {
      if (mounted) setState(() => resendLoading = false);
    }
  }

  Future<void> _loadHomeAndNavigate() async {
    if (!mounted) return;

    final homeProvider = Provider.of<HomeProvider>(
      context,
      listen: false,
    );

    await homeProvider.loadHomeData();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          const Positioned(
            top: -105,
            right: -110,
            child: _DecorativeOrb(size: 255),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight > 42
                              ? constraints.maxHeight - 42
                              : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandRow(),
                            const SizedBox(height: 30),
                            _buildHeading(),
                            const SizedBox(height: 26),
                            _buildOtpCard(context),
                            const SizedBox(height: 22),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TenantConfig.appName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'SECURE ACCESS',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _line),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, size: 12, color: _gold),
              SizedBox(width: 5),
              Text(
                'VERIFIED',
                style: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _softGold,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: _gold),
              SizedBox(width: 7),
              Text(
                'ONE LAST STEP',
                style: TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify it’s\nreally you.',
          style: TextStyle(
            color: _ink,
            fontSize: 35,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to your mobile number.',
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: _gold, size: 17),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _maskedPhone(widget.phone),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _maskedPhone(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.length < 4) return phone;
    return '+91 ${normalized.substring(0, 2)}•••••${normalized.substring(normalized.length - 3)}';
  }

  Widget _buildOtpCard(BuildContext context) {
    final pinDefault = PinTheme(
      width: 44,
      height: 54,
      textStyle: const TextStyle(
        color: _ink,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _line),
      ),
    );

    final pinFocused = pinDefault.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.09),
            blurRadius: 10,
          ),
        ],
      ),
    );

    final pinSubmitted = pinDefault.copyWith(
      decoration: BoxDecoration(
        color: _softGold,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _gold.withOpacity(0.65)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39281B).withOpacity(0.07),
            blurRadius: 30,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ENTER YOUR CODE',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final gap = availableWidth < 330 ? 5.0 : 7.0;
                final pinWidth = ((availableWidth - gap * 5) / 6)
                    .clamp(35.0, 50.0)
                    .toDouble();
                final pinHeight = availableWidth < 330 ? 49.0 : 54.0;

                final responsiveDefault = pinDefault.copyWith(
                  width: pinWidth,
                  height: pinHeight,
                );
                final responsiveFocused = pinFocused.copyWith(
                  width: pinWidth,
                  height: pinHeight,
                );
                final responsiveSubmitted = pinSubmitted.copyWith(
                  width: pinWidth,
                  height: pinHeight,
                );

                return Center(
                  child: Pinput(
                    length: 6,
                    defaultPinTheme: responsiveDefault,
                    focusedPinTheme: responsiveFocused,
                    submittedPinTheme: responsiveSubmitted,
                    separatorBuilder: (_) => SizedBox(width: gap),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !loading,
                    autofocus: false,
                    onChanged: (value) {
                      otpCode = value;
                    },
                    onCompleted: (value) {
                      otpCode = value;
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          _buildVerifyButton(),
          const SizedBox(height: 17),
          Center(
            child: seconds > 0
                ? Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                      children: [
                        const TextSpan(text: 'You can request a new code in '),
                        TextSpan(
                          text: '${seconds}s',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton.icon(
                    onPressed:
                        resendLoading || loading ? null : _resendOtp,
                    icon: resendLoading
                        ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _gold,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(
                      resendLoading ? 'Sending new code…' : 'Resend OTP',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: _muted, size: 13),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Never share your verification code with anyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(loading ? 0.08 : 0.24),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: loading ? null : _verifyOtp,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify & Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 9),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: _gold),
            SizedBox(width: 7),
            Text(
              'SECURE VERIFICATION  •  DOR',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        SizedBox(height: 11),
        Text(
          'Privacy Policy  ·  Terms of Service',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFDCC09A).withOpacity(0.32),
              const Color(0xFFDCC09A).withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
