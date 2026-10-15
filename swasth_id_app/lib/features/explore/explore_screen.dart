import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/animate_in.dart';

// New Explore Widgets
import 'package:swasth_id_app/features/explore/widgets/explore_search_bar.dart';
import 'package:swasth_id_app/features/explore/widgets/scheme_carousel.dart';
import 'package:swasth_id_app/features/explore/widgets/service_grid.dart';
import 'package:swasth_id_app/features/explore/widgets/health_feed.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 120, 0, 100), // Top padding for fixed Search Bar
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // 1. Govt Schemes Carousel
                AnimateIn(
                  delay: Duration(milliseconds: 100),
                  child: SchemeCarousel(),
                ),
                SizedBox(height: 30),

                // 2. Services Grid
                AnimateIn(
                  delay: Duration(milliseconds: 200),
                  child: ServiceGrid(),
                ),
                SizedBox(height: 30),

                // 3. Health Feed
                AnimateIn(
                  delay: Duration(milliseconds: 300),
                  child: HealthFeed(),
                ),
                
                 SizedBox(height: 50),
              ],
            ),
          ),

          // Sticky Transparent Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const ExploreSearchBar(),
            ),
          ),
        ],
      ),
    );
  }
}
