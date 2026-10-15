import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class BodyMapWidget extends StatefulWidget {
  final List<String> selectedParts;
  final Function(String) onPartSelected;

  const BodyMapWidget({
    super.key,
    required this.selectedParts,
    required this.onPartSelected,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              
              // Simple geometric body construction to avoid asset dependency issues
              return Stack(
                alignment: Alignment.center,
                children: [
                   // Base Body Shape (using a simplified stick-figure-like construction with rounded containers)
                   // Head
                   Positioned(top: height * 0.05, child: _buildBodyPartShape(width * 0.18, height * 0.1, Colors.blueGrey[200]!)),
                   // Torso
                   Positioned(top: height * 0.16, child: _buildBodyPartShape(width * 0.25, height * 0.3, Colors.blueGrey[200]!, borderRadius: 8)),
                   // Arms
                   Positioned(top: height * 0.18, left: width * 0.25, child: _buildBodyPartShape(width * 0.08, height * 0.25, Colors.blueGrey[200]!)),
                   Positioned(top: height * 0.18, right: width * 0.25, child: _buildBodyPartShape(width * 0.08, height * 0.25, Colors.blueGrey[200]!)),
                   // Legs
                   Positioned(top: height * 0.47, left: width * 0.32, child: _buildBodyPartShape(width * 0.09, height * 0.3, Colors.blueGrey[200]!)),
                   Positioned(top: height * 0.47, right: width * 0.32, child: _buildBodyPartShape(width * 0.09, height * 0.3, Colors.blueGrey[200]!)),

                  
                  // Touch Targets (Same logic, slightly adjusted positions for the geometric shape)
                  // Head
                  _buildTouchTarget(label: 'Head', top: height * 0.05, left: width * 0.41, width: width * 0.18, height: height * 0.1),
                  // Neck
                  _buildTouchTarget(label: 'Neck', top: height * 0.15, left: width * 0.42, width: width * 0.16, height: height * 0.03),
                  // Shoulders
                  _buildTouchTarget(label: 'Shoulders', top: height * 0.16, left: width * 0.3, width: width * 0.4, height: height * 0.05),
                  // Chest
                  _buildTouchTarget(label: 'Chest', top: height * 0.22, left: width * 0.375, width: width * 0.25, height: height * 0.12),
                  // Stomach
                  _buildTouchTarget(label: 'Stomach', top: height * 0.35, left: width * 0.375, width: width * 0.25, height: height * 0.12),
                  
                  // Arms
                  _buildTouchTarget(label: 'Arms', top: height * 0.18, left: width * 0.25, width: width * 0.1, height: height * 0.25), // Left
                  _buildTouchTarget(label: 'Arms', top: height * 0.18, left: width * 0.65, width: width * 0.1, height: height * 0.25), // Right
                  
                  // Legs
                  _buildTouchTarget(label: 'Legs', top: height * 0.47, left: width * 0.32, width: width * 0.1, height: height * 0.25), // Left
                  _buildTouchTarget(label: 'Legs', top: height * 0.47, left: width * 0.58, width: width * 0.1, height: height * 0.25), // Right

                   // Knees
                  _buildTouchTarget(label: 'Knees', top: height * 0.72, left: width * 0.3, width: width * 0.4, height: height * 0.06),
                  
                   // Feet
                  _buildTouchTarget(label: 'Feet', top: height * 0.8, left: width * 0.3, width: width * 0.4, height: height * 0.08),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text("Tap body parts to select", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildBodyPartShape(double width, double height, Color color, {double borderRadius = 30}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.6), // Darker shade implied or just difference
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildTouchTarget({
    required String label,
    required double top,
    required double left,
    required double width,
    required double height,
    bool isOverlay = false,
  }) {
    final isSelected = widget.selectedParts.contains(label);
    
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () => widget.onPartSelected(label),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.withOpacity(0.6) : Colors.transparent,
            // border: Border.all(color: Colors.red.withOpacity(0.2)), // Debug border
             shape: BoxShape.circle // Roughly circular/oval helpers
          ),
          alignment: Alignment.center,
          child: isSelected 
              ? const Icon(Icons.check, color: Colors.white, size: 20) 
              : null,
        ),
      ),
    );
  }
}
