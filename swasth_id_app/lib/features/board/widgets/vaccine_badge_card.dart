import 'package:flutter/material.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';

class VaccineBadgeCard extends StatefulWidget {
  final String? name;
  final String? vaccine;
  final bool? isVaccinated;

  const VaccineBadgeCard({
    super.key,
    this.name,
    this.vaccine,
    this.isVaccinated,
  });

  @override
  State<VaccineBadgeCard> createState() => _VaccineBadgeCardState();
}

class _VaccineBadgeCardState extends State<VaccineBadgeCard> {
  bool _isLoading = true;
  bool _hasCertificate = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    // Use passed params if provided, otherwise fetch
    if (widget.isVaccinated != null) {
      _isLoading = false;
      _hasCertificate = widget.isVaccinated!;
      _data = {
        'beneficiary': widget.name ?? "User",
        'vaccine': widget.vaccine ?? "Unknown",
        'certificate_id': "MOCK-CERT-123",
        'qr_data': "SWASTH:MOCK"
      };
    } else {
      _fetchCertificate();
    }
  }

  Future<void> _fetchCertificate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final healthId = prefs.getString('health_id');
      
      if (healthId == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
      }

      final result = await ApiService.fetchVaccineCertificate(healthId);
      
      if (mounted) {
        if (result['success']) {
          setState(() {
            _data = result['data'];
            _hasCertificate = _data['is_vaccinated'] ?? false;
            _isLoading = false;
          });
        } else {
           setState(() => _isLoading = false);
        }
      }
    } catch (_) {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink(); // Don't show if loading
    if (!_hasCertificate) return const SizedBox.shrink(); // Hide if not vaccinated
    // ... remainder of build method unchanged ...
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // No decoration here, we do inner one
      child: Stack(
        children: [
            Container(
               decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCAA05D), Color(0xFFF0D69A)], // Gold Gradient
                    begin: Alignment.topLeft, end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))
                  ]
               ),
               padding: const EdgeInsets.all(2), // Border width
               child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Left: Badge & Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Row(
                                 children: [
                                   Icon(Icons.verified_user_rounded, color: const Color(0xFFCAA05D), size: 24),
                                   const SizedBox(width: 8),
                                   const Text("VACCINATED", style: TextStyle(color: Color(0xFFCAA05D), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                 ],
                               ),
                               const SizedBox(height: 12),
                               Text(_data['beneficiary'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                               const SizedBox(height: 4),
                               Text("${_data['vaccine']} | 2 Doses", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                               const SizedBox(height: 4),
                               Text("ID: ${_data['certificate_id']}", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontFamily: 'Monospace')),
                            ],
                          ),
                        ),
                        
                        // Right: QR Code
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: QrImageView(
                            data: _data['qr_data'] ?? "SWASTH_MOCK",
                            version: QrVersions.auto,
                            size: 80.0,
                            foregroundColor: const Color(0xFF002147), // Navy Blue
                          ),
                        )
                      ],
                    ),
                  ),
               ),
            ),
             // "Fully Vaccinated" Badge Ribbon
             Positioned(
               right: -20,
               top: 10,
               child: Transform.rotate(
                 angle: 0.5,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                   color: const Color(0xFF002147),
                   child: const Text("FULL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
               ),
             )
        ],
      )
    );
  }
}
