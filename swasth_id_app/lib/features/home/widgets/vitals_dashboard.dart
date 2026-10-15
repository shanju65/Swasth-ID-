import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class VitalsDashboard extends StatelessWidget {
  const VitalsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildVitalCard(
            label: "Heart Rate",
            value: "72",
            unit: "bpm",
            icon: Icons.favorite,
            color: Colors.redAccent,
            trend: "+2%",
          ),
          _buildVitalCard(
            label: "Blood Pressure",
            value: "120/80",
            unit: "mmHg",
            icon: Icons.speed,
            color: Colors.blueAccent,
            trend: "Normal",
          ),
          _buildVitalCard(
            label: "SPO2",
            value: "98",
            unit: "%",
            icon: Icons.water_drop,
            color: Colors.teal,
            trend: "-1%",
          ),
           _buildVitalCard(
            label: "Weight",
            value: "75",
            unit: "kg",
            icon: Icons.monitor_weight,
            color: Colors.orange,
            trend: "Stable",
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(trend, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: value,
                        style: const TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'sans-serif')), // Ensure font matches
                    TextSpan(
                        text: " $unit",
                        style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
