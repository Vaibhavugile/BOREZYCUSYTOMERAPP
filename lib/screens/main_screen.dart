import 'package:flutter/material.dart';

import '../services/user_helper.dart';
import '../services/review_notification_navigation.dart';
import '../services/fcm_service.dart';
import 'booking_list_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'partner_dashboard_screen.dart';
import 'profile_screen.dart';
import 'reviews_screen.dart';
import 'store_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  bool isGuest = true;
  bool isCheckingUser = true;
  ReviewNotificationIntent? _reviewIntent;
  bool _fcmSetupStarted = false;

  static const Color _background = Color(0xFFFAF8F5);
  static const Color _ink = Color(0xFF29221F);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _muted = Color(0xFF99918A);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _selectedBackground = Color(0xFFF7F0E7);

  List<Widget> get _pages => [
        const HomeScreen(),
        const StorePage(),
        const BookingListScreen(),
        const PartnerDashboardScreen(),
        const ProfileScreen(),
        ReviewsScreen(
          key: ValueKey(_reviewIntent?.identity ?? 'reviews-default'),
          initialBranchCode: _reviewIntent?.branchCode,
          initialPaymentId: _reviewIntent?.paymentId,
          initialReceiptNumber: _reviewIntent?.receiptNumber,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _reviewIntent = ReviewNotificationNavigation.pending.value;
    ReviewNotificationNavigation.pending.addListener(_onReviewNotification);
    _checkGuest();

    if (_reviewIntent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => selectedIndex = 5);
      });
    }
  }

  @override
  void dispose() {
    ReviewNotificationNavigation.pending.removeListener(_onReviewNotification);
    super.dispose();
  }

  void _onReviewNotification() {
    final intent = ReviewNotificationNavigation.pending.value;
    if (intent == null || !mounted) return;

    setState(() {
      _reviewIntent = intent;
      selectedIndex = 5;
    });
  }

  Future<void> _checkGuest() async {
    try {
      final phone = await UserHelper.getPhone();

      if (!mounted) return;

      setState(() {
        isGuest = phone == null || phone.trim().isEmpty;
        isCheckingUser = false;
      });

      // Register the signed-in customer's FCM token using the existing
      // diagnostic FCMService. This is intentionally not called for guests.
      if (!isGuest) {
        _setupCustomerFcm();
      }

      // A notification can arrive while StartupScreen is being shown. If the
      // user is signed in, the pending intent is consumed by this screen.
      if (!isGuest && ReviewNotificationNavigation.pending.value != null) {
        _onReviewNotification();
      }
    } catch (error) {
      debugPrint('Could not check saved user phone: $error');

      if (!mounted) return;

      setState(() {
        isGuest = true;
        isCheckingUser = false;
      });
    }
  }

  Future<void> _setupCustomerFcm() async {
    if (_fcmSetupStarted) return;
    _fcmSetupStarted = true;

    // FCMService.setupFCM() already:
    // - requests notification permission,
    // - waits for the iOS APNs token before requesting the FCM token,
    // - saves the token at customers/{branch}/users/{phone},
    // - updates it when the token refreshes,
    // - subscribes to branch_{branch},
    // - records diagnostic messages for the OTP screen.
    //
    // Its internal try/catch keeps notification setup failures from
    // interrupting the customer's signed-in app experience.
    await FCMService.setupFCM();
  }

  Future<void> _onItemTapped(int index) async {
    if (index < 0 || index >= 6) return;

    if (isGuest && (index == 2 || index == 3 || index == 4 || index == 5)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );

      if (mounted) {
        await _checkGuest();
      }
      return;
    }

    if (selectedIndex == index || !mounted) return;

    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingUser) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: CircularProgressIndicator(
            color: _gold,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _line, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34251B).withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.search_rounded,
                    activeIcon: Icons.travel_explore_rounded,
                    label: 'Browse',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                    label: 'Rentals',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.diamond_outlined,
                    activeIcon: Icons.diamond_rounded,
                    label: 'Partner',
                    showLock: isGuest,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.rate_review_outlined,
                    activeIcon: Icons.rate_review_rounded,
                    label: 'Reviews',
                    showLock: isGuest,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool showLock = false,
  }) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _onItemTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
              decoration: BoxDecoration(
                color: isSelected ? _selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 3,
                    width: isSelected ? 18.0 : 0.0,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(
                      width: 28,
                      height: 26,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? activeIcon : icon,
                            size: 22,
                            color: isSelected ? _ink : _muted,
                          ),
                          if (showLock)
                            Positioned(
                              right: -1,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _line),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 8,
                                  color: _gold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: isSelected ? 10.5 : 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _ink : _muted,
                      letterSpacing: isSelected ? 0.1 : 0,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
