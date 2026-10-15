import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'package:swasth_id_app/core/constants/api_constants.dart';

class SwasthAiService {
  // Using 127.0.0.1:8000 as per previous verification
  static const String _baseUrl = ApiConstants.baseUrl;

  // Fetch all chat sessions for a user
  static Future<List<dynamic>> getSessions(String healthId) async {
    final uri = Uri.parse('$_baseUrl/chat/sessions?health_id=$healthId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching sessions: $e');
    }
    return [];
  }

  // Fetch messages for a specific session
  static Future<List<dynamic>> getMessages(String sessionId) async {
    final uri = Uri.parse('$_baseUrl/chat/messages/$sessionId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
    return [];
  }

  // Create a new session manually
  static Future<Map<String, dynamic>> createSession(String healthId, String title) async {
    final uri = Uri.parse('$_baseUrl/chat/session?health_id=$healthId&title=$title');
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error creating session: $e');
    }
    return {};
  }

  static Future<Map<String, dynamic>> askAi(String question, {XFile? image, String? sessionId, String? healthId}) async {
    // Construct URL (no query params)
    final uri = Uri.parse('$_baseUrl/swasth-ai/ask');
    
    try {
      var request = http.MultipartRequest('POST', uri);
      
      // Add text fields
      request.fields['question'] = question;
      if (sessionId != null) request.fields['session_id'] = sessionId;
      if (healthId != null) request.fields['health_id'] = healthId;
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: image.name,
          ),
        );
      }

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'answer': 'Error: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      return {
        'answer': 'Connection Error: $e'
      };
    }
  }
}
