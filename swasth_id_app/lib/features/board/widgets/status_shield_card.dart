import 'package:flutter/material.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusShieldCard extends StatefulWidget {
  const StatusShieldCard({super.key});

  @override
  State<StatusShieldCard> createState() => _StatusShieldCardState();
}

class _StatusShieldCardState extends State<StatusShieldCard> with SingleTickerProviderStateMixin {
  String _status = "Loading...";
  Color _color = Colors.grey;
  String _message = "Checking health records...";
  bool _isLoading = true;
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fetchStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final healthId = prefs.getString('health_id');

      if (healthId == null) {
        if (mounted) {
            setState(() {
            _status = "No ID";
            _message = "Create Health ID first";
            _isLoading = false;
            });
        }
        return;
      }

      final result = await ApiService.fetchHealthStatus(healthId);
      
      if (mounted) {
        if (result['success']) {
          final data = result['data'];
          setState(() {
            _status = data['status'] == "SAFE" ? "YOU ARE SAFE" : data['status'];
            _color = Color(int.parse(data['color'].replaceAll('#', '0xFF')));
            _message = data['message'];
            _isLoading = false;
          });
        } else {
           setState(() {
            _status = "Unknown";
            _message = "Could not fetch status";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
         setState(() {
            _status = "Error";
            _message = "Connection failed";
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isLoading ? Colors.grey[200] : _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isLoading ? Colors.grey : _color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (_isLoading)
            const CircularProgressIndicator()
          else ...[
             ScaleTransition(
               scale: _scaleAnimation,
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: _color.withOpacity(0.2),
                 ),
                 child: Icon(Icons.security, size: 60, color: _color),
               ),
             ),
             const SizedBox(height: 16),
             Text(
               _status,
               style: TextStyle(
                 fontSize: 24,
                 fontWeight: FontWeight.w900,
                 color: _color,
                 letterSpacing: 1.2
               ),
             ),
             const SizedBox(height: 8),
             Text(
               _message,
               textAlign: TextAlign.center,
               style: TextStyle(
                 fontSize: 14,
                 color: Colors.grey[700],
                 fontWeight: FontWeight.w500
               ),
             ),
             const SizedBox(height: 16),
             // Aarogya Setu bottom text
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.check_circle, size: 16, color: _color),
                 const SizedBox(width: 4),
                 Text(
                   "Verified by Swasth Cloud",
                   style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.bold),
                 )
               ],
             )
          ]
        ],
      ),
    );
  }
}
