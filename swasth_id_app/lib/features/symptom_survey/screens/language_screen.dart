import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/symptom_survey/screens/survey_screen.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.language, size: 40, color: AppColors.primaryColor),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select Language\nभाषा चुनें\nமொழியைத் தேர்ந்தெடுக்கவும்',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'For voice-guided assistant\nआवाज-निर्देशित सहायक के लिए',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              
              _LanguageCard(
                label: 'English',
                subLabel: 'Voice & Text',
                icon: 'A',
                onTap: () => _startSurvey(context, 'en'),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                label: 'हिंदी',
                subLabel: 'Hindi',
                icon: 'अ',
                onTap: () => _startSurvey(context, 'hi'),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                label: 'தமிழ்',
                subLabel: 'Tamil',
                icon: 'அ',
                onTap: () => _startSurvey(context, 'ta'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _startSurvey(BuildContext context, String langCode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyScreen(languageCode: langCode)),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final String icon;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
