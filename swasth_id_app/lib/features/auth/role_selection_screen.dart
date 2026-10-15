import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/features/worker/personal_details_screen.dart';
import 'package:swasth_id_app/features/doctor/doctor_home_screen.dart';
import 'package:swasth_id_app/navigation/bottom_nav.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String mobile;
  const RoleSelectionScreen({super.key, required this.mobile});

  Future<void> _selectRole(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setString('mobile', mobile);

    if (!context.mounted) return;

    if (role == 'Health Worker') {
      // Check if registration is complete (persisted locally)
      final isRegistered = prefs.getBool('is_registered') ?? false;

      if (isRegistered) {
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PersonalDetailsScreen(mobile: mobile)),
        );
      }
    } else {
      // Doctor Logic
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _selectRole(context, 'Health Worker'),
                child: const Text('Health Worker'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 60,
              child: OutlinedButton(
                onPressed: () => _selectRole(context, 'Doctor'),
                child: const Text('Doctor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
