import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';

import 'package:geolocator/geolocator.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class DoctorRecommendationScreen extends StatefulWidget {
  final String specialty;
  const DoctorRecommendationScreen({super.key, required this.specialty});

  @override
  State<DoctorRecommendationScreen> createState() => _DoctorRecommendationScreenState();
}

class _DoctorRecommendationScreenState extends State<DoctorRecommendationScreen> {
  String _locationStatus = "Locating you...";
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndDoctors();
  }

  Future<void> _fetchLocationAndDoctors() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
           _locationStatus = "Location disabled. Showing general results.";
           _doctors = _getMockDoctors(widget.specialty);
           _isLoading = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = "Permission denied. Showing general results.";
             _doctors = _getMockDoctors(widget.specialty);
             _isLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationStatus = "Found you at: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
        // Here we would normally call an API with lat/long
        _doctors = _getMockDoctors(widget.specialty); // Still mock, but simulated "nearby"
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _locationStatus = "Could not locate. Showing list.";
         _doctors = _getMockDoctors(widget.specialty);
         _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                   Expanded( // Wrapped in Expanded to prevent overflow
                    child: Text(
                      "Recommended Doctors", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Subheader with Location Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_searching, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Specialty: ${widget.specialty}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading ? "Locating you..." : _locationStatus,
                          style: TextStyle(color: Colors.blue[800], fontSize: 13),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

          
          // Google Maps Search Button (Real Data)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _launchMapsSearch,
              icon: const Icon(Icons.map, color: Colors.white),
              label: Text("Find ${widget.specialty} on Google Maps (Real)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4), // Google Blue
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Doctor List Area - Replaced with Maps Instructions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.arrow_upward, size: 40, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    "We recommend searching for a '${widget.specialty}' directly on Google Maps for the most accurate and real-time results near you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber)
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(child: Text("Swasth ID does not promote specific private clinics. Please verify doctor credentials independently.")),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }


  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(doc['specialty'], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(doc['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(doc['distance'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          
          // Button
          ElevatedButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking request sent!")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            ),
            child: const Text("Book", style: TextStyle(fontSize: 12, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _launchMapsSearch() async {
    final query = "${widget.specialty} near me";
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Maps")));
      }
    }
  }

  List<Map<String, dynamic>> _getMockDoctors(String specialty) {
    // Provide relevant doctors based on specialty
    final base = [
      {
        'name': 'Dr. Ananya Sharma', 
        'specialty': specialty, 
        'rating': 4.8, 
        'distance': '1.2 km'
      },
      {
        'name': 'Dr. Rajesh Kumar', 
        'specialty': specialty, 
        'rating': 4.5, 
        'distance': '2.5 km'
      },
      {
        'name': 'Dr. Sarah Joseph', 
        'specialty': specialty, 
        'rating': 4.9, 
        'distance': '3.0 km'
      },
    ];
    return base;
  }
}
