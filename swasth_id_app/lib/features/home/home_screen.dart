import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/profile/widgets/app_drawer.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/features/home/widgets/flip_health_card.dart';
import 'package:swasth_id_app/features/home/widgets/vitals_dashboard.dart';
import 'package:swasth_id_app/features/home/widgets/disease_heatmap_widget.dart';
import 'package:swasth_id_app/features/home/widgets/risk_status_card.dart';
import 'package:swasth_id_app/features/board/widgets/vaccine_badge_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      drawer: const AppDrawer(), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for floating nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 24),
            
            // 1. HERO: Flip Health ID
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FlipHealthCard(),
            ),
            
            const SizedBox(height: 32),
            
            // 2. VITALS DASHBOARD
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "My Vitals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
              ),
            ),
             const SizedBox(height: 12),
            const VitalsDashboard(),
            
            const SizedBox(height: 32),
            
            // 3. DISEASE RADAR (New Heatmap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                   const Text(
                    "Disease Radar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text("LIVE", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            const DiseaseHeatMapWidget(),
            
            const SizedBox(height: 32),

            // 4. PRIORITY ACTIONS
             const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Priority Attention",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor),
              ),
            ),
            const SizedBox(height: 12),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: RiskStatusCard(),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: VaccineBadgeCard(
                  name: "Vishal jain",
                  vaccine: "Covishield",
                  isVaccinated: true),
            ),
            
             const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primaryColor, size: 28), // Dark color for light bg
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 12),
          Column(
             crossAxisAlignment: CrossAxisAlignment.start, // Fixed: Was causing error because 'child' was misplaced
             children: [
               const Text("Good Morning,", style: TextStyle(color: Colors.grey, fontSize: 12)),
               const Text("Vishal Jain", style: TextStyle(color: AppColors.textColor, fontSize: 20, fontWeight: FontWeight.bold)),
             ],
          ),
          const Spacer(),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
             child: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryColor),
          )
        ],
      ),
    );
  }

  Widget _buildRecentUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upcoming Vaccination",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "COVID-19 Booster • 2 Days left",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
