import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

import 'home_screen.dart';
import 'browse_screen.dart';
import 'rentals_screen.dart';
import 'profile_screen.dart';
import 'booking_list_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    BrowseScreen(),
    BookingListScreen(),
    ProfileScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[selectedIndex],

      bottomNavigationBar: Container(

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 20,
            )
          ],
        ),

        child: BottomNavigationBar(

          currentIndex: selectedIndex,

          onTap: onItemTapped,

          type: BottomNavigationBarType.fixed,

          selectedItemColor: AppColors.primary,

          unselectedItemColor: Colors.grey,

          showUnselectedLabels: true,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "HOME",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "BROWSE",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              label: "RENTALS",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "PROFILE",
            ),

          ],
        ),
      ),
    );
  }
}