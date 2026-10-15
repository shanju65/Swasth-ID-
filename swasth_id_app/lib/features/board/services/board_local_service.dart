import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BoardLocalService {
  static const String _medsKey = 'medications_list';
  static const String _vaccinesKey = 'vaccinations_list';

  // --- Medications ---
  
  // Get all medications
  static Future<List<Map<String, dynamic>>> getMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_medsKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add a medication
  static Future<void> addMedication(Map<String, dynamic> med) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> current = await getMedications();
    current.add(med);
    await prefs.setString(_medsKey, jsonEncode(current));
  }

  // Toggle status (taken/pending)
  // We identify by 'id' (timestamp created)
  static Future<void> toggleMedicationStatus(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> current = await getMedications();
    
    // Reset status if it's a new day? 
    // For simplicity MVP: just toggle string. Real app needs date checking.
    // Let's assume the list is "Today's Schedule" and resets manually or by logic.
    
    final index = current.indexWhere((m) => m['id'] == id);
    if (index != -1) {
      final oldStatus = current[index]['status'] ?? 'pending';
      current[index]['status'] = oldStatus == 'pending' ? 'taken' : 'pending';
      await prefs.setString(_medsKey, jsonEncode(current));
    }
  }

  // Delete medication
  static Future<void> deleteMedication(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> current = await getMedications();
    current.removeWhere((m) => m['id'] == id);
    await prefs.setString(_medsKey, jsonEncode(current));
  }

  // --- Vaccinations ---

  static Future<List<String>> getTakenVaccines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_vaccinesKey) ?? [];
  }

  static Future<void> updateTakenVaccines(List<String> takenList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_vaccinesKey, takenList);
  }
}
