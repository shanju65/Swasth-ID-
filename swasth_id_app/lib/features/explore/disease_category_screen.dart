import 'package:flutter/material.dart';

class DiseaseCategoryScreen extends StatelessWidget {
  final String categoryName;

  const DiseaseCategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Common Diseases',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Disease 1\n• Disease 2\n• Disease 3',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Symptoms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fever, Headache, Cough, Fatigue, etc.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Prevention Tips',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Wash hands regularly\n• Drink boiled water\n• Maintain hygiene',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
