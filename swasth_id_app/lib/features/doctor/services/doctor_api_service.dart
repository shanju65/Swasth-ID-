import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:swasth_id_app/core/constants/api_constants.dart';

class DoctorApiService {
  static const String _base = ApiConstants.baseUrl;

  // -------------------------------------------------------
  // GET /view-profile/{health_id}
  // Returns personal + medical details of a patient
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> getPatientProfile(String healthId) async {
    final uri = Uri.parse('$_base/view-profile/$healthId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Patient not found (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // -------------------------------------------------------
  // GET /visits/list?health_id=...
  // Returns List<dynamic> of visits for a patient
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> getPatientVisits(String healthId) async {
    final uri = Uri.parse('$_base/visits/list?health_id=$healthId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Backend may return a list or an object with a 'visits' key
        final list = decoded is List ? decoded : (decoded['visits'] ?? []);
        return {'success': true, 'data': list};
      } else {
        return {'success': false, 'message': 'Could not load visits', 'data': []};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  // -------------------------------------------------------
  // POST /visits/create  (delegates params from AddVisitScreen)
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> createVisit({
    required String healthId,
    required String facilityName,
    required String district,
    required String state,
    required String visitType,
    required String chiefComplaint,
    String? symptoms,
    double? temperature,
    String? bp,
    int? spo2,
    bool vaccineGiven = false,
    String? vaccineName,
    String? nextDoseDate,
    bool referred = false,
    String? referredTo,
    String? referralReason,
    String? doctorName,
    String? specialization,
  }) async {
    final Map<String, String> queryParams = {
      'health_id': healthId,
      'facility_name': facilityName,
      'district': district,
      'state': state,
      'visit_type': visitType,
      'chief_complaint': chiefComplaint,
      'symptoms': symptoms ?? chiefComplaint,
      'vaccine_given': vaccineGiven.toString(),
      'referred': referred.toString(),
    };

    if (temperature != null) queryParams['temperature_c'] = temperature.toString();
    if (bp != null) queryParams['bp'] = bp;
    if (spo2 != null) queryParams['spo2'] = spo2.toString();
    if (vaccineName != null) queryParams['vaccine_name'] = vaccineName;
    if (nextDoseDate != null) queryParams['next_dose_due_date'] = nextDoseDate;
    if (referredTo != null) queryParams['referred_to'] = referredTo;
    if (referralReason != null) queryParams['referral_reason'] = referralReason;
    if (doctorName != null) queryParams['doctor_name'] = doctorName;
    if (specialization != null) queryParams['specialization'] = specialization;

    final uri = Uri.parse('$_base/visits/create').replace(queryParameters: queryParams);
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // -------------------------------------------------------
  // Stub: AI summary (future endpoint)
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> getAiSummary(String healthId) async {
    // Placeholder until /swasth-ai/summary/{healthId} is live
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'success': true,
      'data': {
        'chronic_conditions': 'No chronic conditions recorded',
        'recent_illness': 'Awaiting data from visit history',
        'recent_tests': 'No recent lab reports on file',
        'last_visit_summary': 'AI summary will be generated after visit data is available',
      }
    };
  }

  // -------------------------------------------------------
  // Live API for AI patient summary
  // -------------------------------------------------------
  static Future<Map<String, dynamic>> getPatientSummary(String healthId) async {
    final uri = Uri.parse('$_base/patient-summary/$healthId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'API returned ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
