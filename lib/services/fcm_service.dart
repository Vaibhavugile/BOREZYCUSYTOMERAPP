import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tenant_config.dart';

class FCMService {

  static Future<void> setupFCM() async {

    /// 🔥 1. Ask permission (iOS mainly)
    await FirebaseMessaging.instance.requestPermission();

    /// 🔥 2. Get token
    final token = await FirebaseMessaging.instance.getToken();

    print("🔥 FCM TOKEN: $token");

    if (token == null) return;

    /// 🔥 3. Get user phone (your doc ID)
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null) return;

    final cleanPhone = phone.replaceAll("+91", "");

    /// 🔥 4. Save token in Firestore
    await FirebaseFirestore.instance
        .collection("customers")
        .doc(TenantConfig.branchCode)
        .collection("users")
        .doc(cleanPhone)
        .update({
      "fcmToken": token,
    });

    /// 🔥 5. Subscribe to branch topic
    final branch = TenantConfig.branchCode;

    await FirebaseMessaging.instance
        .subscribeToTopic("branch_$branch");

    print("✅ Subscribed to branch_$branch");
  }
}