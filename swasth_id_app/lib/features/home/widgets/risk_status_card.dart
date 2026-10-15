import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiskStatusCard extends StatefulWidget {
  const RiskStatusCard({super.key});

  @override
  State<RiskStatusCard> createState() => _RiskStatusCardState();
}

class _RiskStatusCardState extends State<RiskStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Color _statusColor = AppColors.success;
  String _statusText = "SAFE";
  String _message = "You are safe.";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final healthId = prefs.getString('health_id');
      
      if (healthId != null) {
        final result = await ApiService.fetchHealthStatus(healthId);
        if (mounted && result['success']) {
           setState(() {
             final data = result['data'];
             _statusText = data['status'];
             _message = data['message'];
             // Parse Hex color
             String hex = data['color'].toString().replaceAll("#", "");
             _statusColor = Color(int.parse("0xFF$hex"));
             _isLoading = false;
           });
        }
      } else {
        setState(() => _isLoading = false); // Default safe
      }
    } catch (_) {
       setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1), // Light BG
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
           FadeTransition(
             opacity: _controller,
             child: Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: _statusColor.withOpacity(0.2),
                 shape: BoxShape.circle,
               ),
               child: Icon(Icons.shield_rounded, color: _statusColor, size: 32),
             ),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   _statusText,
                   style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   _message,
                   style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                 ),
               ],
             ),
           ),
           if (_statusText == "AT_RISK")
             ElevatedButton(
               onPressed: () {},
               style: ElevatedButton.styleFrom(backgroundColor: _statusColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
               child: const Text("Isolate"),
             )
        ],
      )
    );
  }
}
