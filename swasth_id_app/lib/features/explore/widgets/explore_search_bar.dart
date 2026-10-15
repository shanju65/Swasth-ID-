import 'package:flutter/material.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search symptoms, doctors, schemes...",
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: AppColors.primaryColor, size: 20),
          ),
        ],
      ),
    );
  }
}
