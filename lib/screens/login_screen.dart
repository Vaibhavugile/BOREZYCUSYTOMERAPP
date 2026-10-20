import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../services/auth_service.dart';
import '../services/tenant_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'main_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final AuthService authService = AuthService();
  final FocusNode _phoneFocusNode = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool isLoading = false;
  bool guestLoading = false;
  bool _otpNavigationStarted = false;

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
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();

    final phone = phoneController.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showMessage('Enter a valid 10-digit mobile number.');
      return;
    }

    if (isLoading || guestLoading) return;

    // Keep the existing review-account flow from the original screen.
    if (phone == '9999999999') {
      await _openOtpScreen(phone);
      return;
    }

    setState(() {
      isLoading = true;
      _otpNavigationStarted = false;
    });

    try {
      await authService.sendOtp(
        phone: phone,
        codeSent: () async {
          if (!mounted || _otpNavigationStarted) return;
          _otpNavigationStarted = true;
          await _openOtpScreen(phone);
        },
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to send OTP. Please try again.');
        debugPrint('sendOtp error: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openOtpScreen(String phone) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          authService: authService,
          phone: phone,
        ),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    if (guestLoading || isLoading) return;

    setState(() {
      guestLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;

      final homeProvider = Provider.of<HomeProvider>(
        context,
        listen: false,
      );

      await homeProvider.loadHomeData();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
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
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('Guest sign-in error: $error');
      _showMessage(
        'Could not continue as guest. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          guestLoading = false;
        });
      }
    }
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          const Positioned(
            top: -110,
            right: -105,
            child: _DecorativeOrb(size: 260),
          ),
          Positioned(
            left: -100,
            top: MediaQuery.of(context).size.height * 0.43,
            child: const _DecorativeOrb(size: 190, muted: true),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      18,
                      24,
                      24 + (bottomInset > 0 ? 8 : 0),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 42 > 0
                            ? constraints.maxHeight - 42
                            : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopMark(),
                          const SizedBox(height: 30),
                          _buildHeading(),
                          const SizedBox(height: 28),
                          _buildLoginCard(),
                          const SizedBox(height: 20),
                          _buildTrustFooter(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMark() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_rounded,
            color: Colors.white,
            size: 25,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'THE RENTAL EDIT',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: _gold),
              SizedBox(width: 5),
              Text(
                'PREMIUM',
                style: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
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
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _softGold,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waving_hand_rounded, size: 14, color: _gold),
              SizedBox(width: 7),
              Text(
                'YOUR STYLE JOURNEY STARTS HERE',
                style: TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 37,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: _ink,
            ),
            children: [
              const TextSpan(text: 'Dress up.\n'),
              TextSpan(
                text: 'Stand out.',
                style: TextStyle(
                  color: _gold,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Discover statement styles for your special moments. '
          'Sign in to make every occasion unforgettable.',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39281B).withOpacity(0.07),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your mobile number to receive a secure OTP.',
            style: TextStyle(
              color: _muted,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 23),
          const Text(
            'MOBILE NUMBER',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _phoneFocusNode,
            builder: (context, child) {
              final focused = _phoneFocusNode.hasFocus;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: focused ? _gold : _line,
                    width: focused ? 1.4 : 1,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: _gold.withOpacity(0.08),
                            blurRadius: 14,
                          ),
                        ]
                      : [],
                ),
                child: child,
              );
            },
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇮🇳', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 5),
                      Text(
                        '+91',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    maxLength: 10,
                    enabled: !isLoading && !guestLoading,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Mobile number',
                      hintStyle: TextStyle(
                        color: Color(0xFFB6ADA4),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    onSubmitted: (_) => sendOtp(),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 19),
          _buildPrimaryButton(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider(color: _line, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: _muted.withOpacity(0.85),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _line, height: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuestButton(),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 13, color: _muted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Your number is used only to secure your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final busy = isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 55,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(busy ? 0.10 : 0.27),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: busy || guestLoading ? null : sendOtp,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue with OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 10),
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

  Widget _buildGuestButton() {
    return OutlinedButton(
      onPressed: guestLoading || isLoading ? null : _continueAsGuest,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: _line),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: guestLoading
          ? const SizedBox(
              height: 19,
              width: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_gold),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore_outlined, size: 18),
                SizedBox(width: 9),
                Text(
                  'Explore as guest',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 14, color: _gold),
            SizedBox(width: 7),
            Text(
              'SECURE SIGN-IN  •  MADE FOR YOUR MOMENTS',
              style: TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          'Privacy Policy  ·  Terms of Service',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted.withOpacity(0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({
    required this.size,
    this.muted = false,
  });

  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: muted
                ? [
                    const Color(0xFFE9DCC9).withOpacity(0.30),
                    const Color(0xFFE9DCC9).withOpacity(0.00),
                  ]
                : [
                    const Color(0xFFDCC09A).withOpacity(0.34),
                    const Color(0xFFDCC09A).withOpacity(0.00),
                  ],
          ),
        ),
      ),
    );
  }
}
