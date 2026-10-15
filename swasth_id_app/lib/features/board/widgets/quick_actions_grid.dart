import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onRecordsTap;
  final VoidCallback onAiTap;
  final VoidCallback onUploadTap;
  final VoidCallback onPhcTap;

  const QuickActionsGrid({
    super.key,
    required this.onRecordsTap,
    required this.onAiTap,
    required this.onUploadTap,
    required this.onPhcTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5, // Wider buttons
          children: [
            _buildActionButton(
              'View Records',
              Icons.folder_shared_outlined,
              Colors.blue,
              onRecordsTap,
            ),
            _buildActionButton(
              'Swasth AI',
              Icons.auto_awesome_outlined,
              Colors.purple,
              onAiTap,
            ),
            _buildActionButton(
              'Upload Doc',
              Icons.upload_file,
              Colors.orange,
              onUploadTap,
            ),
            _buildActionButton(
              'Nearby PHC',
              Icons.local_hospital_outlined,
              Colors.green,
              onPhcTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          // Theme-based background (Primary Blue Tint)
          color: AppColors.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                   color: color.withOpacity(0.3), // Icon color glow
                   blurRadius: 8,
                   offset: const Offset(0, 2)
                  )
                ]
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
