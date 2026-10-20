
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  String? _currentOtp;
  String? _currentPhone;

  /// Generate a six-digit OTP.
  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP using MSG91 WhatsApp template.
  Future<void> sendOtp({
    required String phone,
    required Function() codeSent,
  }) async {
    final otp = _generateOtp();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('otp_phone', phone);
    await prefs.setString('otp_code', otp);

    _currentOtp = otp;
    _currentPhone = phone;

    final url = Uri.parse(
      'https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/',
    );

    final body = {
      'integrated_number': '918793744117',
      'content_type': 'template',
      'payload': {
        'messaging_product': 'whatsapp',
        'type': 'template',
        'template': {
          'name': 'otppp_login',
          'language': {
            'code': 'en',
            'policy': 'deterministic',
          },
          'namespace': '966353f8_de57_41d3_b22b_286d3ad61238',
          'to_and_components': [
            {
              'to': ['91$phone'],
              'components': {
                'body_1': {
                  'type': 'text',
                  'value': otp,
                },
                'button_1': {
                  'subtype': 'url',
                  'type': 'text',
                  'value': otp,
                },
              },
            },
          ],
        },
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'authkey': '499846AoYOdUNzyF69fb27a5P1',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Do not print the OTP or authentication key.
      codeSent();
    } else {
      throw Exception(
        'Failed to send OTP. HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }
  }

  /// Manually verify the OTP.
  Future<void> verifyOtp(String phone, String otp) async {
    final prefs = await SharedPreferences.getInstance();

    final savedPhone = prefs.getString('otp_phone');
    final savedOtp = prefs.getString('otp_code');

    if (savedPhone == phone && savedOtp == otp) {
      await prefs.remove('otp_phone');
      await prefs.remove('otp_code');

      _currentOtp = null;
      _currentPhone = null;
      return;
    }

    throw Exception('Invalid phone number or OTP.');
  }
}
