import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  final List<Map<String, dynamic>> services = const [
    {'name': 'Doctors', 'icon': Icons.medical_services_outlined, 'color': AppColors.primaryColor},
    {'name': 'Lab Tests', 'icon': Icons.science_outlined, 'color': Colors.purple},
    {'name': 'Pharmacy', 'icon': Icons.local_pharmacy_outlined, 'color': Colors.orange},
    {'name': 'Ambulance', 'icon': Icons.emergency, 'color': Colors.red},
    {'name': 'Blood Bank', 'icon': Icons.bloodtype_outlined, 'color': Colors.redAccent},
    {'name': 'Insurance', 'icon': Icons.health_and_safety_outlined, 'color': Colors.teal},
    {'name': 'Clinics', 'icon': Icons.local_hospital_outlined, 'color': Colors.green},
    {'name': 'Surgeries', 'icon': Icons.monitor_heart_outlined, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Find Services",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
               TextButton(onPressed: (){}, child: const Text("See All"))
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final item = services[index];
            return Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item['icon'], color: item['color'], size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['name'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                )
              ],
            );
          },
        ),
      ],
    );
  }
}
