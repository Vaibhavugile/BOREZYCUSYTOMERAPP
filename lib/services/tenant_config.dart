import 'dart:convert';
import 'package:flutter/services.dart';

class TenantConfig {

  static String branchCode = "";
  static String appName = "";
  static String supportPhone = "";

  static Future<void> load() async {

    final jsonString =
        await rootBundle.loadString('assets/config/tenant_config.json');

    final data = jsonDecode(jsonString);

    branchCode = data["branchCode"] ?? "";
    appName = data["appName"] ?? "";
    supportPhone = data["supportPhone"] ?? "";

  }

}