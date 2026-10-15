import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:image_picker/image_picker.dart';

import 'package:swasth_id_app/core/constants/api_constants.dart';

class VisitService {
  static const String baseUrl = ApiConstants.baseUrl;

  // 1. Create Visit
  static Future<Map<String, dynamic>> createVisit({
    required String healthId,
    required String facilityName,
    required String district,
    required String state,
    required String visitType,
    required String chiefComplaint,
    // Vitals
    double? temperature,
    String? bp,
    int? spo2,
    // Vaccination
    bool vaccineGiven = false,
    String? vaccineName,
    String? nextDoseDate,
    // Referral
    bool referred = false,
    String? referredTo,
    String? referralReason,
    // New Fields
    String? doctorName,
    String? specialization,
    String? attachments,
  }) async {
    // Note: Backend requires 'symptoms' but user didn't ask for it in UI.
    // We send empty string or duplicate chiefComplaint to avoid 422.
    final Map<String, dynamic> queryParams = {
      'health_id': healthId,
      'facility_name': facilityName,
      'district': district,
      'state': state,
      'visit_type': visitType,
      'chief_complaint': chiefComplaint,
      'symptoms': chiefComplaint, // Sending complaint as symptoms for now
      
      // Optional fields
      if (temperature != null) 'temperature_c': temperature.toString(),
      if (bp != null) 'bp': bp,
      if (spo2 != null) 'spo2': spo2.toString(),
      
      'vaccine_given': vaccineGiven.toString(),
      if (vaccineName != null) 'vaccine_name': vaccineName,
      if (nextDoseDate != null) 'next_dose_due_date': nextDoseDate,
      
      'referred': referred.toString(),
      if (referredTo != null) 'referred_to': referredTo,
      if (referralReason != null) 'referral_reason': referralReason,

      if (doctorName != null) 'doctor_name': doctorName,
      if (specialization != null) 'specialization': specialization,
      if (attachments != null) 'attachments': attachments,
    };

    final uri = Uri.parse('$baseUrl/visits/create').replace(queryParameters: queryParams);

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

  // 2. Get Visits
  static Future<List<dynamic>> getVisits(String healthId) async {
    final uri = Uri.parse('$baseUrl/visits/list?health_id=$healthId');
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('Failed to load visits: $e');
    }
  }

  // 3. Upload Prescription
  static Future<Map<String, dynamic>> uploadPrescription(String visitId, XFile file) async {
    final uri = Uri.parse('$baseUrl/upload-prescription?visit_id=$visitId');
    final request = http.MultipartRequest('POST', uri);
    
    // Read bytes for web/desktop compat
    final bytes = await file.readAsBytes();
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
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

  // 4. OCR Read
  static Future<String> readOcrText(String filePath) async {
    // Backend expects 'file_path' as query param
    final uri = Uri.parse('$baseUrl/ocr-read?file_path=$filePath');
    
    try {
      final response = await http.post(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ocr_text'] ?? '';
      } else {
        return 'OCR Failed: ${response.body}';
      }
    } catch (e) {
      return 'OCR Error: $e';
    }
  }

  // 5. Update Visit
  static Future<Map<String, dynamic>> updateVisit({
    required String visitId,
    String? chiefComplaint,
    double? temperature,
    String? bp,
    int? spo2,
    String? doctorName,
    String? specialization,
  }) async {
    final Map<String, String> queryParams = {
      'visit_id': visitId,
      if (chiefComplaint != null) 'chief_complaint': chiefComplaint,
      if (temperature != null) 'temperature_c': temperature.toString(),
      if (bp != null) 'bp': bp,
      if (spo2 != null) 'spo2': spo2.toString(),
      if (doctorName != null) 'doctor_name': doctorName,
      if (specialization != null) 'specialization': specialization,
    };

    final uri = Uri.parse('$baseUrl/visits/update').replace(queryParameters: queryParams);

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
}
