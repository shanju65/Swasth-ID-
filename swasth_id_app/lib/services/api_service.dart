import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:swasth_id_app/core/constants/api_constants.dart';

class ApiService {
  // STRICT FOR WEB: Use 127.0.0.1
  static const String baseUrl = ApiConstants.baseUrl;

  // -------------------------
  // WORKER REGISTRATION FLOW
  // -------------------------

  // 1. Personal Details
  static Future<Map<String, dynamic>> submitPersonalDetails({
    required String mobile,
    required String name,
    required int age,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
  }) async {
    // Construct Query Params
    final queryParams = {
      'mobile': mobile,
      'name': name,
      'age': age.toString(),
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    };

    final uri = Uri.parse('$baseUrl/personal-details').replace(queryParameters: queryParams);

    try {
      final response = await http.post(uri);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 2. Medical Details
  static Future<Map<String, dynamic>> submitMedicalDetails({
    required String mobile,
    required double height,
    required double weight,
    required String bloodGroup,
    required String vaccinationStatus,
    required String allergies,
  }) async {
    final queryParams = {
      'mobile': mobile,
      'height_cm': height.toString(),
      'weight_kg': weight.toString(),
      'blood_group': bloodGroup,
      'vaccination_status': vaccinationStatus,
      'allergies': allergies,
    };

    final uri = Uri.parse('$baseUrl/medical-details').replace(queryParameters: queryParams);

    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 3. Upload ID Proof
  static Future<Map<String, dynamic>> uploadIdProof({
    required String mobile,
    required Uint8List fileBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$baseUrl/upload-id-proof?mobile=$mobile');

    final request = http.MultipartRequest('POST', uri);
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ),
    );

    try {
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // 4. Confirm ID & Generate QR
  static Future<Map<String, dynamic>> confirmIdVerification({
    required String mobile,
    required String idType,
    required String idNumber,
  }) async {
    final queryParams = {
      'mobile': mobile,
      'id_type': idType,
      'id_number': idNumber,
    };

    final uri = Uri.parse('$baseUrl/confirm-id-verification').replace(queryParameters: queryParams);

    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------------
  // DOCTOR FLOW
  // -------------------------

  static Future<Map<String, dynamic>> getPatientProfile(String healthId) async {
    final uri = Uri.parse('$baseUrl/view-profile/$healthId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------------
  // AAROGYA SETU FEATURES
  // -------------------------

  static Future<Map<String, dynamic>> fetchHealthStatus(String healthId) async {
    final uri = Uri.parse('$baseUrl/health/status/$healthId');

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchVaccineCertificate(String healthId) async {
    final uri = Uri.parse('$baseUrl/health/vaccine-certificate/$healthId');

    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
