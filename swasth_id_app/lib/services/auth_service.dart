import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:swasth_id_app/core/constants/api_constants.dart';
class AuthService {
  // Hardcoded IP for physical device testing - DO NOT USE localhost
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final url = Uri.parse('$baseUrl/auth/send-otp?mobile=$mobile');
    
    try {
      print('🚀 Sending OTP via $url');
      final response = await http.post(url);
      print('📩 Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'verification_id': data['verification_id']
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send OTP (${response.statusCode})'
        };
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return {
        'success': false,
        'message': 'Connection Error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String otp, String verificationId, String mobile) async {
    final uri = Uri.parse(
        '$baseUrl/auth/verify-otp?otp=$otp&verification_id=$verificationId&mobile=$mobile');
    
    try {
      print('🚀 Verifying OTP via $uri');
      final response = await http.post(uri);
      print('📩 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'is_existing_user': data['is_existing_user'],
          'health_id': data['health_id'],
          'message': data['message'] ?? 'Verified'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['detail'] ?? 'Verification failed'
        };
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return {
        'success': false,
        'message': 'Connection Error: $e'
      };
    }
  }
}
