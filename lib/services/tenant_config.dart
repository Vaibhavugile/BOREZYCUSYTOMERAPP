import 'dart:convert';
import 'package:flutter/services.dart';

class TenantConfig {

  /// 🔥 BASIC INFO
  static String branchCode = "";
  static String appName = "";
  static String supportPhone = "";

  /// 🔥 APP BRANDING
  static String appIcon = "";

  /// 🔥 STORE INFO
  static String storeName = "";
  static String storeTagline = "";
  static String storeAddress = "";
  static String storeTiming = "";

  /// 🔥 STORE MEDIA
  static String storeImage = "";

  /// 🔥 SOCIAL LINKS
  static String instagramUrl = "";
  static String facebookUrl = "";
  static String googleMapUrl = "";

  static Future<void> load() async {

    final jsonString = await rootBundle.loadString(
      'assets/config/tenant_config.json',
    );

    final data = jsonDecode(jsonString);

    /// 🔥 BASIC INFO
    branchCode = data["branchCode"] ?? "";
    appName = data["appName"] ?? "";
    supportPhone = data["supportPhone"] ?? "";

    /// 🔥 APP BRANDING
    appIcon = data["appIcon"] ?? "";

    /// 🔥 STORE INFO
    storeName = data["storeName"] ?? "";
    storeTagline = data["storeTagline"] ?? "";
    storeAddress = data["storeAddress"] ?? "";
    storeTiming = data["storeTiming"] ?? "";

    /// 🔥 STORE MEDIA
    storeImage = data["storeImage"] ?? "";

    /// 🔥 SOCIAL LINKS
    instagramUrl = data["instagramUrl"] ?? "";
    facebookUrl = data["facebookUrl"] ?? "";
    googleMapUrl = data["googleMapUrl"] ?? "";
  }
}