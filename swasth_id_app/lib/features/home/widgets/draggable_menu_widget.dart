import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/swasth_ai/swasth_ai_screen.dart';
import 'package:swasth_id_app/features/symptom_survey/screens/language_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraggableMenuWidget extends StatefulWidget {
  const DraggableMenuWidget({super.key});

  @override
  State<DraggableMenuWidget> createState() => _DraggableMenuWidgetState();
}

class _DraggableMenuWidgetState extends State<DraggableMenuWidget> with SingleTickerProviderStateMixin {
  Offset _offset = const Offset(20, 600); // Initial safe position
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  
  // Quadrant flags
  bool _isLeft = true;
  bool _isTop = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  void _updateQuadrant(Size screenSize) {
    setState(() {
      // Logic: If past horizontal center -> Right
      // If past vertical center -> Bottom
      _isLeft = _offset.dx < (screenSize.width / 2) - 30; // -30 buffer for FAB center
      _isTop = _offset.dy < screenSize.height / 2;
    });
  }

  void _snapToCorner(Size screenSize) {
    const double fabSize = 60;
    const double padding = 20;
    const double safeBottom = 100; // Bottom nav / safe area

    double targetX = _offset.dx < screenSize.width / 2 
        ? padding 
        : screenSize.width - fabSize - padding;
        
    double targetY = _offset.dy < screenSize.height / 2 
        ? kToolbarHeight + padding // Avoid status bar/app bar
        : screenSize.height - fabSize - safeBottom;

    setState(() {
      _offset = Offset(targetX, targetY);
      _updateQuadrant(screenSize);
    });
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _callSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final sosNumber = prefs.getString('emergency_phone') ?? '112'; 
    final Uri launchUri = Uri(scheme: 'tel', path: sosNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 1. CLOSED STATE: Just the FAB blocks the corner
    if (!_isOpen && !_controller.isAnimating) {
      return Positioned(
        left: _offset.dx,
        top: _offset.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _offset += details.delta;
              _updateQuadrant(screenSize);
            });
          },
          onPanEnd: (details) => _snapToCorner(screenSize),
          child: _buildFab(),
        ),
      );
    }

    // 2. OPEN/ANIMATING STATE: Full screen stack to catch touches
    return Stack(
      children: [
        // Transparent Backdrop to close on outside tap
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.black.withOpacity(0.01)), // Tiny opacity to force hit test
          ),
        ),

        // Menu Items
        Positioned(
          top: _isTop ? _offset.dy + 70 : null,
          bottom: !_isTop ? (screenSize.height - _offset.dy) + 10 : null,
          left: _isLeft ? _offset.dx : null,
          right: !_isLeft ? (screenSize.width - _offset.dx) - 60 : null,
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: _isTop ? -1.0 : 1.0,
            child: Column(
              crossAxisAlignment: _isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem("Assess Symptoms", Icons.medical_services, const Color(0xFF6C63FF),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()))),
                const SizedBox(height: 12),
                _buildMenuItem("Swasth AI", Icons.smart_toy, Colors.purpleAccent,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SwasthAiScreen()))),
                const SizedBox(height: 12),
                _buildMenuItem("Nearby Hospitals", Icons.local_hospital, Colors.teal, 
                    () async {
                         final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospital+near+me");
                         if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }),
                const SizedBox(height: 12),
                _buildMenuItem("SOS Emergency", Icons.sos, Colors.redAccent, _callSOS, isSos: true),
              ],
            ),
          ),
        ),

        // The FAB (Now Draggable even when open)
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
               setState(() {
                 _offset += details.delta;
                 _updateQuadrant(screenSize);
               });
            },
            onPanEnd: (details) => _snapToCorner(screenSize),
            child: _buildFab(),
          ),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)], // Green Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11998e).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(_controller), // Rotate 45deg
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String label, IconData icon, Color color, VoidCallback onTap, {bool isSos = false}) {
    return GestureDetector(
      onTap: () {
        _toggle();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: _isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!_isLeft) ...[ _buildLabel(label), const SizedBox(width: 12) ],

          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: color, // Back to Solid Color
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24), // White Icon
          ),

          if (_isLeft) ...[ const SizedBox(width: 12), _buildLabel(label) ],
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50), // Dark Slate Blue for Premium Contrast
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
      ),
    );
  }
}


