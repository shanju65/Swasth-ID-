import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:swasth_id_app/core/constants/api_constants.dart';

/// Result model for Aadhaar OCR scan.
class AadhaarOcrResult {
  final bool success;
  final String? aadhaarNumber;
  final String? name;
  final String? dob;
  final String? gender;
  final OcrConfidence confidence;
  final String? errorMessage;

  const AadhaarOcrResult({
    required this.success,
    this.aadhaarNumber,
    this.name,
    this.dob,
    this.gender,
    this.confidence = OcrConfidence.none,
    this.errorMessage,
  });

  factory AadhaarOcrResult.fromJson(Map<String, dynamic> json) {
    return AadhaarOcrResult(
      success: json['success'] == true,
      aadhaarNumber: json['aadhaar_number']?.toString(),
      name: json['name']?.toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      confidence: _parseConfidence(json['overall_confidence']?.toString()),
      errorMessage: json['error']?.toString(),
    );
  }

  factory AadhaarOcrResult.error(String message) => AadhaarOcrResult(
        success: false,
        confidence: OcrConfidence.none,
        errorMessage: message,
      );

  static OcrConfidence _parseConfidence(String? raw) {
    switch (raw) {
      case 'high':
        return OcrConfidence.high;
      case 'medium':
        return OcrConfidence.medium;
      case 'low':
        return OcrConfidence.low;
      default:
        return OcrConfidence.none;
    }
  }

  /// Returns true if at least one useful field was extracted.
  bool get hasData =>
      (aadhaarNumber?.isNotEmpty ?? false) ||
      (name?.isNotEmpty ?? false) ||
      (dob?.isNotEmpty ?? false) ||
      (gender?.isNotEmpty ?? false);
}

enum OcrConfidence { high, medium, low, none }

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class OcrAadhaarService {
  static const String _base = ApiConstants.baseUrl;

  /// Sends [imageBytes] (JPEG/PNG) to the backend OCR endpoint and returns
  /// a structured [AadhaarOcrResult].
  static Future<AadhaarOcrResult> scanAadhaar({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('$_base/ocr-aadhaar-scan');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final streamResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AadhaarOcrResult.fromJson(json);
      } else {
        return AadhaarOcrResult.error(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AadhaarOcrResult.error('Network error: $e');
    }
  }
}
