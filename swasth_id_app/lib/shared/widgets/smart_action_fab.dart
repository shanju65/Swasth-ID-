import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/bot/health_bot_screen.dart';
import 'package:swasth_id_app/features/profile/emergency_contacts_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartActionFab extends StatefulWidget {
  const SmartActionFab({super.key});

  @override
  State<SmartActionFab> createState() => _SmartActionFabState();
}

class _SmartActionFabState extends State<SmartActionFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), 
        vsync: this
    );
    _expandAnimation = CurvedAnimation(
        parent: _controller, 
        curve: Curves.easeOut
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _handleAction(String action) async {
    // Close menu first
    _toggle();

    switch (action) {
      case 'ai':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthBotScreen()),
        );
        break;
      case 'hospital':
        final Uri url = Uri.parse("https://www.google.com/maps/search/hospitals+near+me");
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open maps')),
               );
             }
        }
        break;
      case 'sos':
        final prefs = await SharedPreferences.getInstance();
        final mobile = prefs.getString('mobile') ?? '';
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EmergencyContactsScreen(mobile: mobile, data: const {})),
          );
        }
        break;
    }
  }

  Widget _buildActionBtn({
    required String label, 
    required IconData icon, 
    required Color color, 
    required String action,
    required double interval
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Interval(interval, 1.0, curve: Curves.easeOut),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: action,
              onPressed: () => _handleAction(action),
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _buildActionBtn(
            label: "Swasth AI", 
            icon: Icons.psychology, 
            color: Colors.purple, 
            action: 'ai',
            interval: 0.0,
          ),
          _buildActionBtn(
            label: "Nearby Hospitals", 
            icon: Icons.local_hospital, 
            color: Colors.blueAccent, 
            action: 'hospital',
            interval: 0.1,
          ),
          _buildActionBtn(
            label: "SOS Emergency", 
            icon: Icons.sos, 
            color: Colors.redAccent, 
            action: 'sos',
            interval: 0.2,
          ),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: _isExpanded ? Colors.grey : AppColors.primaryColor,
          child: Icon(_isExpanded ? Icons.close : Icons.add_circle_outline, size: 28),
        ),
      ],
    );
  }
}
