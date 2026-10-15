import 'package:flutter/material.dart';
import 'package:swasth_id_app/features/profile/emergency_contacts_screen.dart';
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Added Import

class SOSHeaderCard extends StatelessWidget {
  const SOSHeaderCard({super.key});

  Future<void> _handleSOS(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile') ?? '';
  
    if (mobile.isEmpty) {
        if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen(mobile: mobile, data: const {})));
        }
        return;
    }

    // Fetch Profile to get contact
    // Show loading indicator or toast? Ideally quick action.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to Emergency Contact..."), duration: Duration(seconds: 1)));
    
    final result = await ProfileService.fetchProfile(mobile);
    if (result['success']) {
        final data = result['data'];
        final emergency = data['emergency_contacts'] ?? {};
        final phone = emergency['phone'];
        
        if (phone != null && phone.toString().isNotEmpty) {
            final Uri launchUri = Uri(scheme: 'tel', path: phone);
            if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
            } else {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch dialer")));
                 }
            }
        } else {
            // No contact set, go to setup
             if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Emergency Contact Found. Please add one.")));
                Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen(mobile: mobile, data: const {})));
            }
        }
    } else {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to fetch contact. Check internet.")));
        }
    }
  }

  Future<void> _handleHospitals(BuildContext context) async {
    // 1. Check Permissions & Service
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Locating nearby hospitals..."), duration: Duration(seconds: 1)));
    
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enable Location Services")));
          }
          final Uri fallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospitals+near+me");
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied used fallback")));
           }
           final Uri fallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospitals+near+me");
           await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
           return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
           final Uri fallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospitals+near+me");
           await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
           return;
      } 

      // 2. Get Location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 3. Launch Precise Map
      final Uri geoUri = Uri.parse("geo:${position.latitude},${position.longitude}?q=hospitals");
       // Android often handles 'geo:' better with direct intent, but URL launcher supports it.
       // However, 'https://www.google.com/maps/search/?api=1&query=hospitals&center=${position.latitude},${position.longitude}' is safer web-fallback
       
      final Uri mapUrl = Uri.parse("https://www.google.com/maps/search/hospitals/@${position.latitude},${position.longitude},15z");

      if (await canLaunchUrl(mapUrl)) {
          await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
      } else {
           // Fallback to query
          final Uri fallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospitals+near+me");
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }

    } catch (e) {
       print("Location Error: $e");
        final Uri fallbackUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=hospitals+near+me");
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium split-card design
    return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
             colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
             begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [
             BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.4), blurRadius: 12, offset: const Offset(0,6))
          ]
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
               // 1. SOS Call Section (Main)
               Expanded(
                 flex: 3,
                 child: InkWell(
                    onTap: () => _handleSOS(context),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                    child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                       child: Row(
                         children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
                                   Text("Call Contact", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            )
                         ],
                       ),
                    ),
                 ),
               ),
               
               // Divider
               Container(width: 1, color: Colors.white.withOpacity(0.2)),
               
               // 2. Hospital Map Section
               Expanded(
                 flex: 2,
                 child: InkWell(
                    onTap: () => _handleHospitals(context),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                    child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 20),
                       child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Icon(Icons.local_hospital, color: Colors.white.withOpacity(0.9), size: 28),
                             const SizedBox(height: 4),
                             const Text("Nearby", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                       ),
                    ),
                 ),
               )
            ],
          ),
        ),
    );
  }
}
