import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {

  /// 🔥 SAVE PHONE (call after OTP login)
  static Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_phone", phone);
  }

  /// 🔥 GET PHONE (use everywhere)
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_phone");
  }

  /// 🔥 CLEAR (optional - logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_phone");
  }
}