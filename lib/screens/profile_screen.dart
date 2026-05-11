import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../services/tenant_config.dart';
import '../services/user_helper.dart';
import 'credit_history_screen.dart';
import 'booking_list_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  int points = 0;
  int rentals = 0;
  int wishlistCount = 0;
bool isEditingName = false;
  String customerName = "Customer";
  String profileImageUrl = "";

  bool loading = true;
  bool savingProfile = false;

  final TextEditingController nameController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  /// 🔥 LOAD PROFILE
  Future<void> loadProfileData() async {

    final cleanPhone = await UserHelper.getPhone();
    if (cleanPhone == null) return;

    final branch = TenantConfig.branchCode;

    final customerDoc = await FirebaseFirestore.instance
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(cleanPhone)
        .get();

    if (customerDoc.exists) {

      final data = customerDoc.data()!;

      customerName = data["name"] ?? "Customer";

      profileImageUrl = data["profileImage"] ?? "";

      nameController.text = customerName;

      /* =====================================================
   RENTALS
===================================================== */

final branchStats =
    data["branchStats"] ?? {};

final currentBranchStats =
    branchStats[branch] ?? {};

rentals =
    currentBranchStats["receipts"] ?? 0;

/* =====================================================
   WALLET BALANCE
===================================================== */

final creditQuery =
    await FirebaseFirestore.instance
        .collection("products")
        .doc(branch)
        .collection("creditNotes")
        .where(
          "mobileNumber",
          isEqualTo: cleanPhone,
        )
        .limit(1)
        .get();

if (creditQuery.docs.isNotEmpty) {

  final creditData =
      creditQuery.docs.first.data();

  points =
      (creditData["Balance"] ?? 0)
          .toInt();
}

final wishlistSnapshot =
    await FirebaseFirestore.instance
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(cleanPhone)
        .collection("wishlist")
        .get();

wishlistCount =
    wishlistSnapshot.docs.length;
    }

    setState(() {
      loading = false;
    });
  }

  /// 🔥 PICK + UPLOAD IMAGE
  Future<void> pickProfileImage() async {

    final phone = await UserHelper.getPhone();
    if (phone == null) return;

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      savingProfile = true;
    });

    try {

      final file = File(picked.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child(
            "${TenantConfig.branchCode}_$phone.jpg",
          );

      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("customers")
          .doc(TenantConfig.branchCode)
          .collection("users")
          .doc(phone)
          .set({
        "profileImage": downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        profileImageUrl = downloadUrl;
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
        ),
      );
    }

    setState(() {
      savingProfile = false;
    });
  }

  /// 🔥 SAVE PROFILE
  Future<void> saveProfile() async {

    final phone = await UserHelper.getPhone();
    if (phone == null) return;

    setState(() {
      savingProfile = true;
    });

    try {

      await FirebaseFirestore.instance
          .collection("customers")
          .doc(TenantConfig.branchCode)
          .collection("users")
          .doc(phone)
          .set({

        "name": nameController.text.trim(),
        "profileImage": profileImageUrl,

      }, SetOptions(merge: true));

      setState(() {
        customerName = nameController.text.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated"),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }

    setState(() {
      savingProfile = false;
    });
  }

  /// 🔥 MENU ITEM
  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color iconColor = AppColors.primary,
  }) {

    return ListTile(
      onTap: onTap,

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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(subtitle),

      trailing: const Icon(Icons.chevron_right),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(
        centerTitle: true,

        title: Text(
          TenantConfig.appName,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),


        actions: const [
          
        ],
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// 🔥 PROFILE CARD
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

                  /// 🔥 PROFILE IMAGE
                  Stack(
                    alignment: Alignment.bottomRight,

                    children: [

                      CircleAvatar(
                        radius: 55,
                        backgroundColor:
                            AppColors.primaryLight,

                        backgroundImage:
                            profileImageUrl.isNotEmpty
                                ? NetworkImage(
                                    profileImageUrl,
                                  )
                                : null,

                        child: profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 45,
                                color: AppColors.primary,
                              )
                            : null,
                      ),

                      GestureDetector(

                        onTap: savingProfile
                            ? null
                            : pickProfileImage,

                        child: Container(
                          padding: const EdgeInsets.all(8),

                          decoration: const BoxDecoration(
                            gradient:
                                AppGradients.primaryGradient,
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 EDIT NAME
                 /// 🔥 NAME + EDIT
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    Expanded(
      child: TextField(
        controller: nameController,
        enabled: isEditingName,
        textAlign: TextAlign.center,

        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Enter your name",
        ),

        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    GestureDetector(
      onTap: () {
        setState(() {
          isEditingName = true;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),

        child: const Icon(
          Icons.edit,
          size: 18,
          color: AppColors.primary,
        ),
      ),
    ),
  ],
),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Text(
                      "Customer",
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 🔥 SAVE BUTTON
                /// 🔥 SAVE BUTTON
if (isEditingName)
  SizedBox(
    width: double.infinity,
    height: 52,

    child: ElevatedButton(

      onPressed: savingProfile
          ? null
          : () async {

              await saveProfile();

              setState(() {
                isEditingName = false;
              });
            },

      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      child: savingProfile
          ? const CircularProgressIndicator(
              color: Colors.white,
            )
          : const Text(
              "Save Profile",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  ),

                  const SizedBox(height: 24),

                  const Divider(),

                  const SizedBox(height: 20),

                  /// 🔥 STATS
               Row(

  mainAxisAlignment:
      MainAxisAlignment.spaceEvenly,

  children: [

    /* =====================================================
       RENTALS
    ===================================================== */

    GestureDetector(

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) =>
                const BookingListScreen(),
          ),
        );
      },

      child: Column(

        children: [

          Container(

            padding:
                const EdgeInsets.all(14),

            decoration: BoxDecoration(

              gradient:
                  const LinearGradient(

                colors: [

                  Color(0xFFE8F1FF),

                  Color(0xFFD9E8FF),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(20),

              boxShadow: [

                BoxShadow(

                  blurRadius: 10,

                  color: Colors.blue
                      .withOpacity(.12),
                )
              ],
            ),

            child: Column(

              children: [

                const Icon(

                  Icons.calendar_month_rounded,

                  color:
                      Color(0xFF2563EB),

                  size: 22,
                ),

                const SizedBox(height: 6),

                Text(

                  "$rentals",

                  style: const TextStyle(

                    fontSize: 22,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const Text(

            "RENTALS",

            style: TextStyle(

              fontSize: 12,

              letterSpacing: 1.2,

              color: Colors.black54,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    /* =====================================================
       WISHLIST
    ===================================================== */

    GestureDetector(

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) =>
                const WishlistScreen(),
          ),
        );
      },

      child: Column(

        children: [

          Container(

            padding:
                const EdgeInsets.all(14),

            decoration: BoxDecoration(

              gradient:
                  const LinearGradient(

                colors: [

                  Color(0xFFFFEEF1),

                  Color(0xFFFFDDE4),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(20),

              boxShadow: [

                BoxShadow(

                  blurRadius: 10,

                  color: Colors.pink
                      .withOpacity(.12),
                )
              ],
            ),

            child: Column(

              children: [

                const Icon(

                  Icons.favorite_rounded,

                  color:
                      Color(0xFFE11D48),

                  size: 22,
                ),

                const SizedBox(height: 6),

                Text(

  "$wishlistCount",

  style: const TextStyle(

    fontSize: 22,

    fontWeight:
        FontWeight.bold,

    color:
        Color(0xFF1F2937),
  ),
),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const Text(

            "WISHLIST",

            style: TextStyle(

              fontSize: 12,

              letterSpacing: 1.2,

              color: Colors.black54,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    /* =====================================================
       POINTS / WALLET
    ===================================================== */

    GestureDetector(

      onTap: () async {

        final phone =
            await UserHelper.getPhone();

        if (phone == null) return;

        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) =>
                CreditHistoryScreen(
              mobileNumber: phone,
            ),
          ),
        );
      },

      child: Column(

        children: [

          Container(

            padding:
                const EdgeInsets.all(14),

            decoration: BoxDecoration(

              gradient:
                  const LinearGradient(

                colors: [

                  Color(0xFFFFF4D6),

                  Color(0xFFFDE7B0),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(20),

              boxShadow: [

                BoxShadow(

                  blurRadius: 10,

                  color: Colors.amber
                      .withOpacity(.18),
                )
              ],
            ),

            child: Column(

              children: [

                const Icon(

                  Icons.account_balance_wallet_rounded,

                  color:
                      Color(0xFFC69214),

                  size: 22,
                ),

                const SizedBox(height: 6),

                Text(

                  "$points",

                  style: const TextStyle(

                    fontSize: 22,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const Text(

            "POINTS",

            style: TextStyle(

              fontSize: 12,

              letterSpacing: 1.2,

              color: Colors.black54,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ],
),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 ACCOUNT PREF
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account Preferences",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
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
                    icon: Icons.calendar_today,
                    title: "My Bookings",
                    subtitle:
                        "History and upcoming rentals",

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BookingListScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  buildMenuItem(
                    icon: Icons.favorite_border,
                    title: "Wishlist",
                    subtitle:
                        "Items you've saved for later",

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const WishlistScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔥 HELP
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Help & Security",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
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
                    subtitle:
                        "24/7 concierge assistance",
                  ),

                  const Divider(),

                  ListTile(

                    leading: Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                    ),

                    title: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),

                    subtitle: const Text(
                      "Sign out of your account",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "${TenantConfig.appName} V2.4.0",
              style: const TextStyle(
                color: Colors.black45,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}