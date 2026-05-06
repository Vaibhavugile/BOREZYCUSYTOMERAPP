import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tenant_config.dart';
import 'user_helper.dart';

class FCMService {

  static Future<void> setupFCM() async {

    /// 🔥 1. Ask permission
    await FirebaseMessaging.instance.requestPermission();

    /// 🔥 2. Get token
    final token = await FirebaseMessaging.instance.getToken();

    print("🔥 FCM TOKEN: $token");

    if (token == null) return;

    /// 🔥 3. Get phone (from local storage)
    final phone = await UserHelper.getPhone();
    if (phone == null) return;

    final branch = TenantConfig.branchCode;

    /// 🔥 4. Save token safely (FIXED)
    await FirebaseFirestore.instance
        .collection("customers")
        .doc(branch)
        .collection("users")
        .doc(phone)
        .set({
      "fcmToken": token,
    }, SetOptions(merge: true)); // ✅ FIX

    /// 🔥 5. Subscribe to branch topic
    await FirebaseMessaging.instance
        .subscribeToTopic("branch_$branch");

    print("✅ Subscribed to branch_$branch");
  }
}