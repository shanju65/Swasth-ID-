import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/swasth_ai/swasth_ai_screen.dart';
import 'package:swasth_id_app/features/symptom_survey/screens/language_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildActionItem(
                context,
                icon: Icons.medical_services,
                label: "Assess",
                color: const Color(0xFF6C63FF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
              ),
              _buildActionItem(
                context,
                icon: Icons.smart_toy,
                label: "Swasth AI",
                color: Colors.purpleAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwasthAiScreen())),
              ),
              _buildActionItem(
                context,
                icon: Icons.local_hospital,
                label: "Hospitals",
                color: Colors.teal,
                onTap: () async {
                  final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+near+me");
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              _buildActionItem(
                context,
                icon: Icons.sos,
                label: "SOS",
                color: Colors.redAccent,
                onTap: _callSOS,
              ),
               _buildActionItem(
                context,
                icon: Icons.medication,
                label: "Meds",
                color: Colors.orange,
                onTap: () {}, // Todo
              ),
              _buildActionItem(
                context,
                icon: Icons.qr_code_scanner,
                label: "Scan",
                color: Colors.blue,
                onTap: () {}, // Todo
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _callSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final sosNumber = prefs.getString('emergency_phone') ?? '112'; 
    final Uri launchUri = Uri(scheme: 'tel', path: sosNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
