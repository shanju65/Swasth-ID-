import 'package:flutter/material.dart';

class SchemeCarousel extends StatelessWidget {
  const SchemeCarousel({super.key});

  final List<Map<String, dynamic>> schemes = const [
    {
      'title': 'Ayushman Bharat',
      'subtitle': 'PM-JAY Gold Card',
      'color': Color(0xFFE6BF00), // Gold
      'gradient': [Color(0xFFE6BF00), Color(0xFFF7D94C)],
      'icon': Icons.health_and_safety,
    },
    {
      'title': 'Karunya Scheme',
      'subtitle': 'Kerala Goverment',
      'color': Color(0xFF00A651), // Green
      'gradient': [Color(0xFF00A651), Color(0xFF4DB97A)],
      'icon': Icons.local_hospital,
    },
    {
      'title': 'eSanjeevani',
      'subtitle': 'Tele-Consultation',
      'color': Color(0xFF1976D2), // Blue
      'gradient': [Color(0xFF1976D2), Color(0xFF42A5F5)],
      'icon': Icons.video_call,
    },
     {
      'title': 'Maternity Benefit',
      'subtitle': 'Janani Suraksha',
      'color': Color(0xFFE91E63), // Pink
      'gradient': [Color(0xFFE91E63), Color(0xFFF48FB1)],
      'icon': Icons.child_care,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Government Schemes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final item = schemes[index];
              return Container(
                width: 240,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Icon decoration
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        item['icon'],
                        size: 100,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'], color: Colors.white, size: 24),
                          ),
                          const Spacer(),
                          Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(20),
                             ),
                             child: Text(
                               "Apply Now",
                               style: TextStyle(
                                 color: item['color'], 
                                 fontWeight: FontWeight.bold,
                                 fontSize: 10
                               ),
                             ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
