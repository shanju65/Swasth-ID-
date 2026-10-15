import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class RecentVisitsCard extends StatelessWidget {
  final List<dynamic> visits;
  final VoidCallback onViewAll;

  // Constructor accepts list, we handle logic inside
  const RecentVisitsCard({
    super.key,
    required this.visits,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) return const SizedBox.shrink(); // Hide if no data

    // Get most recent visit
    final recentVisit = visits.first;
    
    // Extract advice (Mocking extraction logic as backend might not separate it cleanly yet)
    // We look for 'prescription_url' presence or 'notes' if available in future
    final String doctorAdvice = recentVisit['notes'] ?? 
        "Stay hydrated and complete the prescribed medication course.";
    
    // Parse Date
    final dateStr = recentVisit['created_at'] ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    
    final facility = recentVisit['facility_name'] ?? 'Unknown Facility';
    final type = recentVisit['visit_type'] ?? 'General';

    return Column(
      children: [
        // SECTION 3: LAST DOCTOR ADVICE (Trust Builder)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.format_quote_rounded, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Doctor\'s Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '"$doctorAdvice"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // SECTION 4: RECENT DOCTOR VISIT (Single)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Visit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryColor.withOpacity(0.8), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryColor),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                facility,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$formattedDate • $type',
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(type),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String type) {
    Color color;
    String label;

    if (type.toLowerCase().contains('follow')) {
      color = Colors.orange;
      label = 'Follow-up';
    } else if (type.toLowerCase().contains('refer')) {
      color = Colors.red;
      label = 'Referred';
    } else {
      color = Colors.green;
      label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
