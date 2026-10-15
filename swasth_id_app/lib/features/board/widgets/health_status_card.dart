import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class HealthStatusCard extends StatelessWidget {
  final String district;
  
  // Later this can be dynamic based on backend
  final String alertLevel; 

  const HealthStatusCard({
    super.key,
    required this.district,
    required this.alertLevel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color and message based on alert level
    Color cardColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String message;

    switch (alertLevel.toUpperCase()) {
      case 'HIGH':
        cardColor = const Color(0xFFFF5252); // Red Accent
        icon = Icons.warning_rounded;
        statusTitle = 'High Alert';
        message = 'Significant illness cases reported in $district. Take precautions.';
        break;
      case 'MEDIUM':
        cardColor = const Color(0xFFFFA726); // Orange
        icon = Icons.info_outline;
        statusTitle = 'District Under Watch';
        message = 'Seasonal illness cases reported in $district. Stay cautious.';
        break;
      case 'LOW':
      default:
        cardColor = const Color(0xFF66BB6A); // Green
        icon = Icons.verified_user_rounded;
        statusTitle = 'You are Safe';
        message = 'No major health alerts in $district.';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
