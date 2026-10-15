import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:swasth_id_app/features/doctor/patient_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/features/auth/login_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _manualIdController = TextEditingController();

  void _onScan(String? code) {
    if (code != null && code.isNotEmpty) {
      _navigateToDetails(code);
    }
  }

  void _navigateToDetails(String healthId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientSummaryScreen(healthId: healthId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
               // Logout Logic
               final prefs = await SharedPreferences.getInstance();
               await prefs.clear(); // Clear all session data OR just remove 'role'
               
               if (context.mounted) {
                 Navigator.pushAndRemoveUntil(
                   context,
                   MaterialPageRoute(builder: (context) => const LoginScreen()),
                   (route) => false,
                 );
               }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Scan Patient QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Scanner View
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _onScan(barcode.rawValue);
                        break; // Process first code
                      }
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('- OR -'),
            const SizedBox(height: 16),
            
            TextField(
              controller: _manualIdController,
              decoration: const InputDecoration(
                labelText: 'Enter Health ID Manually',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _navigateToDetails(_manualIdController.text.trim()),
                child: const Text('View Patient Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
