import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Swasth ID Terms of Service",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColor),
            ),
            const SizedBox(height: 20),
             _buildSection("1. Acceptance of Terms", "By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement."),
             _buildSection("2. Medical Disclaimer", "This app provides health records management and initial triage suggestions. It is NOT a replacement for professional medical advice, diagnosis, or treatment."),
             _buildSection("3. Data Privacy", "Your data is encrypted and stored securely. We do not share your personal health information with third parties without your explicit consent."),
             _buildSection("4. User Responsibilities", "You are responsible for maintaining the confidentiality of your account and password."),
             _buildSection("5. Changes to Terms", "We reserve the right to modify these terms at any time. You should check this page regularly."),
             const SizedBox(height: 40),
             Center(
               child: Text(
                 "Last Updated: Oct 2023",
                 style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
