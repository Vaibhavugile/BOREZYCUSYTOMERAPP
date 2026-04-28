import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final String branchCode = "7007";
int points = 0;
  String customerName = "Customer";
  int rentals = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {

  final phone = FirebaseAuth.instance.currentUser!.phoneNumber!;
  final cleanPhone = phone.replaceAll("+91", "");

  /// RENTALS
  final paymentsQuery = await FirebaseFirestore.instance
      .collection("products")
      .doc(branchCode)
      .collection("payments")
      .where("contact", isEqualTo: cleanPhone)
      .get();

  rentals = paymentsQuery.docs.length;

  if (paymentsQuery.docs.isNotEmpty) {
    customerName = paymentsQuery.docs.first["clientName"] ?? "Customer";
  }

  /// CREDIT NOTE → POINTS
  final creditQuery = await FirebaseFirestore.instance
      .collection("products")
      .doc(branchCode)
      .collection("creditNotes")
      .where("mobileNumber", isEqualTo: cleanPhone)
      .where("status", isEqualTo: "active")
      .get();

  if (creditQuery.docs.isNotEmpty) {

    final data = creditQuery.docs.first.data();

    points = int.tryParse(
        data["Balance"].toString()
    ) ?? 0;

  } else {

    points = 0;

  }

  setState(() {
    loading = false;
  });
}

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = AppColors.primary,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "BOREZY",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        leading: const Icon(Icons.menu),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.shopping_bag_outlined),
          )
        ],
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            /// PROFILE CARD
            Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 25,
                  )
                ],
              ),

              child: Column(

                children: [

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [

                      const CircleAvatar(
                        radius: 55,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/300",
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// CUSTOMER NAME
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Customer",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Divider(),

                  const SizedBox(height: 20),

                  /// STATS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      Column(
                        children: [
                          Text(
                            "$rentals",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text("RENTALS")
                        ],
                      ),

                      const Column(
                        children: [
                          Text("0",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text("WISHLIST")
                        ],
                      ),

                    Column(
  children: [
    Text(
      "$points",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    const Text(
      "POINTS",
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    ),
  ],
),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account Preferences",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  buildMenuItem(
                    icon: Icons.straighten,
                    title: "My Measurements",
                    subtitle: "Manage your fit preferences",
                  ),

                  const Divider(),

                  buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: "Addresses",
                    subtitle: "Manage your shipping locations",
                  ),

                  const Divider(),

                  buildMenuItem(
                    icon: Icons.calendar_today,
                    title: "My Bookings",
                    subtitle: "History and upcoming rentals",
                  ),

                  const Divider(),

                  buildMenuItem(
                    icon: Icons.favorite_border,
                    title: "Wishlist",
                    subtitle: "Items you've saved for later",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Help & Security",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  buildMenuItem(
                    icon: Icons.support_agent,
                    title: "Support",
                    subtitle: "24/7 concierge assistance",
                  ),

                  const Divider(),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text("Sign out of your account"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "BOREZY V2.4.0 • CRAFTED FOR STYLE",
              style: TextStyle(color: Colors.black45),
            ),

            const SizedBox(height: 40),

          ],
        ),
      ),

      
    );
  }
}