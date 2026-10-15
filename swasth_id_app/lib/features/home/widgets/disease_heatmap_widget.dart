import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/core/constants/api_constants.dart';

class DiseaseHeatMapWidget extends StatefulWidget {
  const DiseaseHeatMapWidget({super.key});

  @override
  State<DiseaseHeatMapWidget> createState() => _DiseaseHeatMapWidgetState();
}

class _DiseaseHeatMapWidgetState extends State<DiseaseHeatMapWidget> {
  // Coordinates for Kerala Districts (Approx centers)
  final Map<String, LatLng> _districtCoords = {
    'thiruvananthapuram': const LatLng(8.5241, 76.9366),
    'kollam': const LatLng(8.8932, 76.6141),
    'pathanamthitta': const LatLng(9.2648, 76.7870),
    'alappuzha': const LatLng(9.4981, 76.3388),
    'kottayam': const LatLng(9.5916, 76.5222),
    'idukki': const LatLng(9.8494, 76.9802),
    'ernakulam': const LatLng(9.9816, 76.2999),
    'thrissur': const LatLng(10.5276, 76.2144),
    'palakkad': const LatLng(10.7867, 76.6548),
    'malappuram': const LatLng(11.0510, 76.0711),
    'kozhikode': const LatLng(11.2588, 75.7804),
    'wayanad': const LatLng(11.6854, 76.1320),
    'kannur': const LatLng(11.8745, 75.3704),
    'kasaragod': const LatLng(12.5102, 74.9852),
  };

  Set<Circle> _circles = {};
  bool _isLoading = true;
  String? _error;
  
  // Default to Kerala Center
  final CameraPosition _keralaCamera = const CameraPosition(
    target: LatLng(10.5, 76.2), 
    zoom: 7, 
  );

  @override
  void initState() {
    super.initState();
    _fetchHeatMapData();
  }

  Future<void> _fetchHeatMapData() async {
    try {
      // Use the centralized Base URL which is configured for LAN IP
      const String baseUrl = ApiConstants.baseUrl; 
      
      final response = await http.get(Uri.parse('$baseUrl/surveillance/heatmap'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> heatmapData = data['data'];
        _generateCircles(heatmapData);
      } else {
        setState(() {
          _error = "Failed to load map data";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection Error"; // Simplified error for UI
        _isLoading = false;
      });
      print("HeatMap Error: $e");
    }
  }

  void _generateCircles(List<dynamic> data) {
    Set<Circle> newCircles = {};

    for (var item in data) {
      String district = (item['district'] ?? "").toString().toLowerCase();
      int cases = item['cases'] ?? 0;
      String alertLevel = item['alert_level'] ?? "LOW";
      String disease = item['disease'] ?? "Unknown";

      if (_districtCoords.containsKey(district)) {
        Color circleColor;
        double radius;

        if (alertLevel == "HIGH") {
          circleColor = Colors.red.withOpacity(0.5);
          radius = 15000; // 15km
        } else if (alertLevel == "MEDIUM") {
          circleColor = Colors.orange.withOpacity(0.4);
          radius = 10000;
        } else {
          circleColor = Colors.green.withOpacity(0.3);
          radius = 5000;
        }

        newCircles.add(
          Circle(
            circleId: CircleId(district),
            center: _districtCoords[district]!,
            radius: radius,
            fillColor: circleColor,
            strokeColor: circleColor.withOpacity(0.8),
            strokeWidth: 1,
            consumeTapEvents: true,
            onTap: () {
              _showDistrictInfo(district, cases, disease, alertLevel);
            },
          ),
        );
      }
    }

    setState(() {
      _circles = newCircles;
      _isLoading = false;
    });
  }

  void _showDistrictInfo(String district, int cases, String disease, String alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 10))
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: alert == "HIGH" ? Colors.red : Colors.orange, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(district.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Disease Alert", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow("Disease", disease),
            _buildInfoRow("Active Cases", "$cases Cases"),
            _buildInfoRow("Risk Level", alert, isAlert: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Okay, Got it", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14,
            color: isAlert ? (value == "HIGH" ? Colors.red : Colors.orange) : Colors.black87
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _fetchHeatMapData, child: const Text("Retry"))
            ],
          ),
        ),
      );
    }
    
    return Container(
        height: 240, // Map Height
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Google Map using Lite Mode for better scrolling performance in a list
              GoogleMap(
                initialCameraPosition: _keralaCamera,
                circles: _circles,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: true, // Switch to Lite Mode to stop frame drop logs
                myLocationButtonEnabled: false,
                onMapCreated: (controller) {
                   controller.setMapStyle(_mapStyle);
                },
              ),
              
              // Overlay Title
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                  ),
                  child: Row(
                    children: const [
                       Icon(Icons.radar, color: Colors.redAccent, size: 16),
                       SizedBox(width: 6),
                       Text("Live Disease Radar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),

               if (_isLoading)
                 Container(
                   color: Colors.white.withOpacity(0.5),
                   child: const Center(child: CircularProgressIndicator()),
                 )
            ],
          ),
        ),
    );
  }
  
 // Minimalist Map Style
 final String _mapStyle = '''
 [
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadada"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9c9c9"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  }
]
 ''';
}
