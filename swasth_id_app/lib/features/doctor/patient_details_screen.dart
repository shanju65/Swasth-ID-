import 'package:flutter/material.dart';
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';
import 'package:swasth_id_app/features/records/create_visit_screen.dart';
import 'package:swasth_id_app/features/records/visit_detail_screen.dart';
import 'package:swasth_id_app/features/records/visit_list_screen.dart';
import 'package:swasth_id_app/features/doctor/doctor_visit_list_screen.dart';
import 'package:swasth_id_app/features/doctor/patient_analytics_screen.dart';


class PatientDetailsScreen extends StatefulWidget {
  final String healthId;
  const PatientDetailsScreen({super.key, required this.healthId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _visits = [];
  bool _isLoading = true;
  String? _error;

  // AI Summary (generated locally from visit data)
  String _chronicConditions = 'No chronic conditions recorded';
  String _recentIllness = 'Awaiting data from visit history';
  String _recentTests = 'No recent lab reports on file';
  String _lastVisitSummary = 'AI summary will be generated after visit data is available';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final profileResponse = await ProfileService.fetchProfileByHealthId(widget.healthId);
      final visitsResponse = await VisitService.getVisits(widget.healthId);
      if (profileResponse['success']) {
        setState(() {
          _profileData = profileResponse['data'];
          _visits = visitsResponse;
          _isLoading = false;
        });
        _generateAiSummary();
      } else {
        setState(() { _error = profileResponse['message']; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _generateAiSummary() {
    if (_visits.isEmpty) return;

    // Derive recent illness from latest visit chief complaint
    final latest = _visits.first;
    final complaint = latest['chief_complaint'] ?? '';
    if (complaint.isNotEmpty) {
      setState(() {
        _recentIllness = complaint;
        _lastVisitSummary =
            'Last visit at ${latest['facility_name'] ?? 'facility'} on ${_formatDate(latest['created_at'])}. '
            'Chief complaint: $complaint. Visit type: ${latest['visit_type'] ?? 'OPD'}.';
      });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final personal = _profileData?['personal_details'] ?? {};
    final medical = _profileData?['medical_details'] ?? {};
    final name = personal['name'] ?? 'Patient';
    final shortId = widget.healthId.length > 8 ? '${widget.healthId.substring(0, 8)}...' : widget.healthId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Column(
          children: [
            Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Health ID: $shortId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientSnapshot(personal, medical),
                      const SizedBox(height: 16),
                      _buildActionRow(),
                      const SizedBox(height: 16),
                      _buildAiSummaryCard(),
                      const SizedBox(height: 16),
                      _buildVisitHistoryPreview(),
                    ],
                  ),
                ),
    );
  }

  // ─── Patient Snapshot Card ────────────────────────────────────────────────
  Widget _buildPatientSnapshot(Map personal, Map medical) {
    final name = personal['name'] ?? 'Unknown';
    final age = personal['age']?.toString() ?? '?';
    final gender = personal['gender'] ?? '';
    final bloodGroup = medical['blood_group'] ?? 'N/A';
    final bmi = medical['bmi']?.toString() ?? 'N/A';
    final allergies = medical['allergies'] ?? 'None';
    final height = medical['height_cm']?.toString() ?? 'N/A';
    final weight = medical['weight_kg']?.toString() ?? 'N/A';
    final address = '${personal['city'] ?? ''}, ${personal['state'] ?? ''}';
    final vaccination = medical['vaccination_status'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin, color: Color(0xFF2196F3), size: 18),
              const SizedBox(width: 6),
              const Text('PATIENT SNAPSHOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2196F3), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF3F51B5),
                child: Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('$age yrs  •  $gender', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          // Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(bloodGroup, const Color(0xFFFFEBEE), const Color(0xFFE53935), Icons.water_drop),
              _badge('BMI $bmi', const Color(0xFFFFF3E0), const Color(0xFFEF6C00), Icons.monitor_weight_outlined),
              if (vaccination.isNotEmpty)
                _badge(vaccination, const Color(0xFFE8F5E9), const Color(0xFF388E3C), Icons.vaccines),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Height', '$height cm'),
          _infoRow('Weight', '$weight kg'),
          _infoRow('Allergies', allergies, valueColor: allergies != 'None' ? Colors.red : null),
          _infoRow('Address', address),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  // ─── 4-Tab Action Row ─────────────────────────────────────────────────────
  Widget _buildActionRow() {
    final name = _profileData?['personal_details']?['name'] ?? 'Patient';
    return Row(
      children: [
        Expanded(child: _actionButton(Icons.history, 'Visits', const Color(0xFFE8EAF6), const Color(0xFF5C6BC0), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorVisitListScreen(
            healthId: widget.healthId,
            patientName: name,
          )));
        })),
        const SizedBox(width: 8),
        Expanded(child: _actionButton(Icons.analytics, 'Analytics', const Color(0xFFFFF3E0), const Color(0xFFEF6C00), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PatientAnalyticsScreen(
            visits: _visits,
            patientName: name,
          )));
        })),
        const SizedBox(width: 8),
        Expanded(child: _actionButton(Icons.add_circle_outline, 'Add', const Color(0xFFE0F2F1), const Color(0xFF00897B), () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateVisitScreen(healthId: widget.healthId)));
          if (result == true) _fetchData();
        })),
        const SizedBox(width: 8),
        Expanded(child: _actionButton(Icons.folder_open, 'Records', const Color(0xFFF3E5F5), const Color(0xFF8E24AA), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorVisitListScreen(
            healthId: widget.healthId,
            patientName: name,
          )));
        })),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── AI Medical Summary Card ──────────────────────────────────────────────
  Widget _buildAiSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF7E57C2), size: 18),
                const SizedBox(width: 6),
                const Text('AI MEDICAL SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7E57C2), letterSpacing: 0.8)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(20)),
                child: const Text('AI Powered', style: TextStyle(color: Color(0xFF8E24AA), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _aiSummaryRow(Icons.favorite_border, const Color(0xFF5C6BC0), 'Chronic Conditions', _chronicConditions),
          const Divider(height: 24),
          _aiSummaryRow(Icons.sick_outlined, const Color(0xFF00897B), 'Recent Illness', _recentIllness),
          const Divider(height: 24),
          _aiSummaryRow(Icons.biotech_outlined, const Color(0xFFEF6C00), 'Recent Tests', _recentTests),
          const Divider(height: 24),
          _aiSummaryRow(Icons.summarize_outlined, const Color(0xFF8E24AA), 'Last Visit Summary', _lastVisitSummary),
        ],
      ),
    );
  }

  Widget _aiSummaryRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Visit History Preview ────────────────────────────────────────────────
  Widget _buildVisitHistoryPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.show_chart, color: Color(0xFF00897B), size: 18),
                SizedBox(width: 6),
                Text('VISIT HISTORY PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00897B), letterSpacing: 0.8)),
              ]),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitListScreen())),
                child: const Text('View All', style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_visits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No visits recorded yet.', style: TextStyle(color: Colors.grey))),
            )
          else
            ..._visits.take(3).map((visit) => _visitTile(visit)).toList(),
        ],
      ),
    );
  }

  Widget _visitTile(Map visit) {
    final type = visit['visit_type'] ?? 'OPD';
    final complaint = visit['chief_complaint'] ?? 'Visit';
    final doctor = visit['doctor_name'] ?? 'Dr. Unknown Doctor';
    final date = visit['created_at'] ?? '';
    final isEmergency = type.toLowerCase() == 'emergency';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VisitDetailScreen(visit: Map<String, dynamic>.from(visit)))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_box_outlined, color: Color(0xFF00897B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(complaint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$doctor  •  $date', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isEmergency ? const Color(0xFFFFEBEE) : const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(type, style: TextStyle(color: isEmergency ? Colors.red : const Color(0xFF5C6BC0), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
