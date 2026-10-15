import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class BodyHealthCard extends StatelessWidget {
  final double? heightCm;
  final double? weightKg;
  final int? age;
  final double? bmi; 

  const BodyHealthCard({
    super.key,
    this.heightCm,
    this.weightKg,
    this.age,
    this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    if (heightCm == null || weightKg == null) {
      return _buildEmptyState();
    }

    // 1. BMI Logic
    final double actualBmi = bmi ?? (weightKg! / ((heightCm! / 100) * (heightCm! / 100)));
    final String bmiString = actualBmi.toStringAsFixed(1);

    String status;
    Color statusColor;
    String largeMessage;

    if (actualBmi < 18.5) {
      status = 'Underweight';
      statusColor = Colors.orangeAccent;
      largeMessage = 'You are Underweight';
    } else if (actualBmi >= 18.5 && actualBmi <= 24.9) {
      status = 'Fit';
      statusColor = Colors.green;
      largeMessage = 'You are Fit';
    } else if (actualBmi >= 25 && actualBmi <= 29.9) {
      status = 'Overweight';
      statusColor = Colors.orange;
      largeMessage = 'You are Overweight';
    } else {
      status = 'Obese';
      statusColor = Colors.redAccent;
      largeMessage = 'You are Obese';
    }

    // 2. Ideal Weight Logic (Formula: 22 * h^2)
    final double heightM = heightCm! / 100;
    final double idealWeight = 22 * heightM * heightM;
    final double minWeight = 18.5 * heightM * heightM;
    final double maxWeight = 24.9 * heightM * heightM;
    
    final String idealRange = '${minWeight.round()} - ${maxWeight.round()} kg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            // Title and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Vitals',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.textSecondary
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    // border: Border.all(color: statusColor.withOpacity(0.3)), // Cleaner without border
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Metrics Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric('Height', '${heightCm!.round()} cm'),
                _buildDivider(),
                _buildMetric('Weight', '$weightKg kg'),
                _buildDivider(),
                _buildMetric('BMI', bmiString, isHighlight: true, highlightColor: statusColor),
              ],
            ),
            const SizedBox(height: 24),

            // Ideal Weight Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                    ),
                    child: const Icon(Icons.monitor_weight_outlined, color: AppColors.primaryColor, size: 20)
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ideal Weight: ${idealWeight.round()} kg',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target Range: $idealRange',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildMetric(String label, String value, {bool isHighlight = false, Color? highlightColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight ? highlightColor : AppColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_outline, size: 40, color: Colors.grey),
              SizedBox(height: 10),
              Text('Update your profile to see health insights'),
            ],
          ),
        ),
      ),
    );
  }
}
