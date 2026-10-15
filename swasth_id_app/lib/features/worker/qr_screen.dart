import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/navigation/bottom_nav.dart';

class QrScreen extends StatefulWidget {
  final String mobile;
  final String healthId;

  const QrScreen({
    super.key,
    required this.mobile,
    required this.healthId,
  });

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {

  @override
  void initState() {
    super.initState();
    _markRegistrationComplete();
  }

  Future<void> _markRegistrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_registered', true);
    await prefs.setString('health_id', widget.healthId);
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const BottomNav()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration Complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Health ID Generated!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('ID: ${widget.healthId}'),
              const SizedBox(height: 32),
              
              // QR Code
              QrImageView(
                data: widget.healthId,
                version: QrVersions.auto,
                size: 200.0,
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Show this QR code to the doctor to access your medical records.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goHome,
                  child: const Text('Go to Home Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
