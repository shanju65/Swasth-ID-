import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/profile/emergency_contacts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSFloatingActionButton extends StatelessWidget {
  const SOSFloatingActionButton({super.key});

  Future<void> _handleSOS(BuildContext context) async {
    // Navigate safely to Emergency Contacts
    // In a real app, this might also start a countdown to dial 108
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile') ?? '';
    
    if (context.mounted) {
       Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => EmergencyContactsScreen(mobile: mobile, data: const {}))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _handleSOS(context),
      backgroundColor: Colors.redAccent,
      elevation: 4,
      icon: const Icon(Icons.sos_rounded, color: Colors.white),
      label: const Text("SOS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
