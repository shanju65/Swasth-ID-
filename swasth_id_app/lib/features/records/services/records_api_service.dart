import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import '../../../core/constants/api_constants.dart'; // Assume this exists, adjust if needed

class RecordsApiService {
  // Use a fallback URL if ApiConstants is not defined with a getter.
  static const String _baseUrl = ApiConstants.baseUrl; 

  Future<List<VisitGroup>> fetchVisitRecords(String healthId) async {
    final url = Uri.parse('$_baseUrl/api/patients/$healthId/records');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> visitsJson = data['visits'] ?? [];
        
        return visitsJson.map((v) {
          final List<dynamic> docsJson = v['documents'] ?? [];
          final docs = docsJson.map((d) {
            
            // Map the string to the correct enum type
            RecordType rType = RecordType.other;
            try {
               rType = RecordType.values.firstWhere(
                (e) => e.name.toLowerCase() == d['type'].toString().toLowerCase(),
                orElse: () => RecordType.other,
               );
            } catch (_) {}

            return DocumentModel(
              id: d['id'].toString(),
              title: d['title'] ?? 'Untitled',
              type: rType,
              uploadDate: DateTime.parse(d['uploadDate']),
              fileUrl: '$_baseUrl${d['fileUrl']}', // Make relative URL absolute
              isPdf: d['fileUrl'].toString().toLowerCase().endsWith('.pdf')
            );
          }).toList();
          
          return VisitGroup(
            visitId: v['visitId'].toString(),
            visitDate: DateTime.parse(v['visitDate']),
            diagnosis: v['diagnosis'] ?? 'Checkup',
            doctorName: v['doctorName'] ?? '-',
            documents: docs,
            symptoms: v['symptoms'],
            temperature: v['temperature_c'] != null ? double.tryParse(v['temperature_c'].toString()) : null,
            bp: v['bp'],
            spo2: v['spo2'] != null ? int.tryParse(v['spo2'].toString()) : null,
            visitType: v['visitType'],
            facilityName: v['facilityName'],
            district: v['district'],
            state: v['state'],
            specialization: v['specialization'],
            vaccineGiven: v['vaccineGiven'] == true,
            vaccineName: v['vaccineName'],
            nextDoseDate: v['nextDoseDate'],
            referred: v['referred'] == true,
            referredTo: v['referredTo'],
            referralReason: v['referralReason'],
          );
        }).toList();
      } else {
        throw Exception('Failed to load records. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching records: $e');
    }
  }

  Future<bool> uploadMedicalRecord({
    required String healthId,
    String? visitId,
    required String documentType,
    required String filePath,
  }) async {
    final url = Uri.parse('$_baseUrl/api/records/upload');
    
    try {
      var request = http.MultipartRequest('POST', url);
      
      // Add text fields
      request.fields['health_id'] = healthId;
      if (visitId != null && visitId.isNotEmpty) {
        request.fields['visit_id'] = visitId;
      }
      request.fields['document_type'] = documentType;
      
      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Upload failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print('Error uploading record: $e');
      return false;
    }
  }
}
