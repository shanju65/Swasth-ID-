import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swasth_id_app/core/constants/api_constants.dart';

class ProfileService {
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> fetchProfile(String mobile) async {
    final url = Uri.parse('$baseUrl/profile/details?mobile=$mobile');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updatePersonalDetails(Map<String, dynamic> data) async {
      // Endpoint: /personal-details
      final url = Uri.parse('$baseUrl/personal-details?mobile=${data['mobile']}&name=${data['name']}&age=${data['age']}&gender=${data['gender']}&address=${data['address']}&city=${data['city']}&state=${data['state']}&pincode=${data['pincode']}');
      
      try {
        final response = await http.post(url);
         if (response.statusCode == 200) {
          return {'success': true, 'message': 'Personal details updated'};
        } else {
           return {'success': false, 'message': 'Failed to update personal details'};
        }
      } catch (e) {
         return {'success': false, 'message': e.toString()};
      }
  }
  
    static Future<Map<String, dynamic>> updateMedicalDetails(Map<String, dynamic> data) async {
      // Endpoint: /medical-details
      final url = Uri.parse('$baseUrl/medical-details?mobile=${data['mobile']}&height_cm=${data['height_cm']}&weight_kg=${data['weight_kg']}&blood_group=${data['blood_group']}&vaccination_status=${data['vaccination_status']}&allergies=${data['allergies']}');
      
      try {
        final response = await http.post(url);
         if (response.statusCode == 200) {
          return {'success': true, 'message': 'Medical details updated'};
        } else {
           return {'success': false, 'message': 'Failed to update medical details'};
        }
      } catch (e) {
         return {'success': false, 'message': e.toString()};
      }
  }
  static Future<Map<String, dynamic>> updateEmergencyContacts(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/update-emergency-contacts?mobile=${data['mobile']}&name=${data['name']}&phone=${data['phone']}&relation=${data['relation']}');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Emergency contacts updated'};
      } else {
        return {'success': false, 'message': 'Failed to update emergency contacts'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateInsuranceDetails(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/update-insurance-details?mobile=${data['mobile']}&provider=${data['provider']}&policy_no=${data['policy_no']}&valid_till=${data['valid_till']}&tpa=${data['tpa']}');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Insurance details updated'};
      } else {
        return {'success': false, 'message': 'Failed to update insurance details'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
