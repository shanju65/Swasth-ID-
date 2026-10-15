import 'package:flutter/material.dart';

class HealthFeed extends StatelessWidget {
  const HealthFeed({super.key});

  final List<Map<String, dynamic>> articles = const [
    {
      'title': 'Mental Wellness: 5 Simple Tips',
      'subtitle': 'Boost your mood naturally.',
      'image': 'assets/images/mental_health.png', // Fallback needed
      'color': Colors.blue,
      'time': '5 min read'
    },
    {
      'title': 'Flu Season Alert in Kerala',
      'subtitle': 'Precautionary measures released.',
      'image': 'assets/images/flu.png',
      'color': Colors.redAccent,
      'time': '2 min read'
    },
     {
      'title': 'Yoga for Beginners',
      'subtitle': 'Start your journey today.',
      'image': 'assets/images/yoga.png',
      'color': Colors.teal,
      'time': '10 min read'
    },
    {
      'title': 'Understanding Diabetes',
      'subtitle': 'Myth busters and facts.',
      'image': 'assets/images/diabetes.png',
      'color': Colors.orange,
      'time': '7 min read'
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
            "Health Feed",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final article = articles[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: (article['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.article, color: article['color'], size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                             color: (article['color'] as Color).withOpacity(0.1),
                             borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            article['time'],
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: article['color']
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article['subtitle'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
