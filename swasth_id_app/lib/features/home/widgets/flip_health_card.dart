import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart'; // Import QR package

class FlipHealthCard extends StatefulWidget {
  final String name;
  final String healthId;

  const FlipHealthCard({
    super.key, 
    this.name = "Vishal Jain", // Default for now
    this.healthId = "9812-3211-1233"
  });

  @override
  State<FlipHealthCard> createState() => _FlipHealthCardState();
}

class _FlipHealthCardState extends State<FlipHealthCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          final isBack = angle >= (pi / 2);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi), // Mirror back
                    child: _buildBack(),
                  )
                : _buildFront(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3C), Color(0xFF2C3E50)], // Premium Dark Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SWASTH ID",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Image.asset('assets/images/chip.png', height: 30, errorBuilder: (c,e,s) => const Icon(Icons.nfc, color: Colors.white30, size: 30)),
            ],
          ),
          const Spacer(),
          Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "HID: ${widget.healthId}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              letterSpacing: 2, // Monospace look
              fontFamily: 'monospace', 
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("VERIFIED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Text("Tap to flip", style: TextStyle(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Text(
            "Scan for Medical Records",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.grey.shade200)
             ),
             // Real QR Code Generator
             child: QrImageView(
               data: widget.healthId,
               version: QrVersions.auto,
               size: 100.0,
               backgroundColor: Colors.white,
             ),
          ),
        ],
      ),
    );
  }
}
