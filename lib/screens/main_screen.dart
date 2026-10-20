import 'package:flutter/material.dart';

import '../services/user_helper.dart';
import 'booking_list_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'partner_dashboard_screen.dart';
import 'profile_screen.dart';
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

  static const Color _background = Color(0xFFFAF8F5);
  static const Color _ink = Color(0xFF29221F);
  static const Color _gold = Color(0xFFB68A52);
  static const Color _muted = Color(0xFF99918A);
  static const Color _line = Color(0xFFECE5DC);
  static const Color _selectedBackground = Color(0xFFF7F0E7);

  final List<Widget> _pages = const [
    HomeScreen(),
    StorePage(),
    BookingListScreen(),
    PartnerDashboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkGuest();
  }

  Future<void> _checkGuest() async {
    try {
      final phone = await UserHelper.getPhone();

      if (!mounted) return;

      setState(() {
        isGuest = phone == null || phone.trim().isEmpty;
        isCheckingUser = false;
      });
    } catch (error) {
      debugPrint('Could not check saved user phone: $error');

      if (!mounted) return;

      setState(() {
        isGuest = true;
        isCheckingUser = false;
      });
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (index < 0 || index >= _pages.length) return;

    // Rentals, Partner and Profile require a signed-in user.
    if (isGuest && (index == 2 || index == 3 || index == 4)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
      );

      // Refresh saved login state when the login screen closes.
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
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
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
              padding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 1,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Use a non-overshooting curve and non-negative width so
                  // fractional pixel rounding cannot produce negative width.
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
