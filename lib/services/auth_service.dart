import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AuthService {

  String? _currentOtp;
  String? _currentPhone;

  /// 🔢 GENERATE OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// 📤 SEND OTP VIA MSG91 WHATSAPP
  Future<void> sendOtp({
    required String phone,
    required Function() codeSent,
  }) async {

    final otp = _generateOtp();

    /// 🔐 STORE TEMP (basic version)
    _currentOtp = otp;
    _currentPhone = phone;

    final url = Uri.parse(
      "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/",
    );

    final body = {
      "integrated_number": "919096457700", // your MSG91 number
      "content_type": "template",
      "payload": {
        "messaging_product": "whatsapp",
        "type": "template",
        "template": {
          "name": "otp_login",
          "language": {
            "code": "en",
            "policy": "deterministic"
          },
          "namespace": "4ffa31a1_ffeb_487b_9817_7ab865d7addf",
          "to_and_components": [
            {
              "to": ["91$phone"], // user number
              "components": {
  "body_1": {
    "type": "text",
    "value": otp
  },
  "button_1": {
    "subtype": "url",
    "type": "text",
    "value": otp // 🔥 SAME OTP HERE
  }
}
            }
          ]
        }
      }
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "authkey": "499846AoYOdUNzyF69fb27a5P1", // 🔐 replace
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ OTP Sent: $otp"); // debug only
      codeSent();
    } else {
      print("❌ MSG91 Error: ${response.body}");
      throw Exception("Failed to send OTP");
    }
  }

  /// 🔍 VERIFY OTP (MANUAL)
  Future<void> verifyOtp(String phone, String otp) async {
    if (_currentPhone == phone && _currentOtp == otp) {
      print("✅ OTP Verified");
      return;
    } else {
      throw Exception("Invalid OTP");
    }
  }
}