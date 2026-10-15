import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/board/board_screen.dart';
import 'package:swasth_id_app/features/explore/explore_screen.dart';
import 'package:swasth_id_app/features/home/home_screen.dart';
import 'package:swasth_id_app/features/profile/profile_screen.dart';
import 'package:swasth_id_app/features/records/visit_list_screen.dart';
import 'package:swasth_id_app/features/records/visit_list_screen.dart';
import 'package:swasth_id_app/features/home/widgets/draggable_menu_widget.dart';

import 'package:swasth_id_app/features/profile/widgets/app_drawer.dart';
import 'package:swasth_id_app/features/home/widgets/quick_action_sheet.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) return; // Middle button handled by FAB
    setState(() {
      _currentIndex = index > 2 ? index - 1 : index; // Re-map index because of gap
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const VisitListScreen(),
      BoardScreen(isVisible: _currentIndex == 2),
      const ExploreScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      
      body: _FadeIndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15), // Pushed significantly deeper to level with tabs
        child: FloatingActionButton(
          heroTag: 'dock_fab', // Fix: Unique tag to prevent collisions
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const QuickActionSheet(),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: Container(
            width: 60, // Slightly larger
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4011998e),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0, // Tighter notch
        clipBehavior: Clip.antiAlias, 
        color: Colors.white,
        child: SizedBox(
          height: 70, // Increased from 60 to prevent overflow
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(0, Icons.home_rounded, "Home"),
              _buildTabItem(1, Icons.article_rounded, "Records"),
              const SizedBox(width: 48), // Gap for FAB
              _buildTabItem(2, Icons.dashboard_rounded, "Board"), // Index 2 in UI, 2 in Logic
              _buildTabItem(3, Icons.explore, "Explore"),         // Index 3 in UI, 3 in Logic
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    // Logic mapping: UI index -> Screen index
    // UI: 0, 1, GAP, 2, 3
    // Screens: 0, 1, 2, 3
    // This simple match works if we treat them linearly in the Row
    
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? AppColors.primaryColor : Colors.grey.shade400;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _currentIndex = widget.index;
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _currentIndex = widget.index;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: _currentIndex,
        children: widget.children,
      ),
    );
  }
}
