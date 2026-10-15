import 'package:flutter/material.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';

class DoctorVisitListScreen extends StatefulWidget {
  final String healthId;
  final String patientName;

  const DoctorVisitListScreen({
    super.key,
    required this.healthId,
    required this.patientName,
  });

  @override
  State<DoctorVisitListScreen> createState() => _DoctorVisitListScreenState();
}

class _DoctorVisitListScreenState extends State<DoctorVisitListScreen> {
  List<dynamic> _visits = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final visits = await VisitService.getVisits(widget.healthId);
      setState(() { _visits = visits; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _visits;
    final q = _searchQuery.toLowerCase();
    return _visits.where((v) {
      return (v['facility_name'] ?? '').toLowerCase().contains(q) ||
             (v['chief_complaint'] ?? '').toLowerCase().contains(q) ||
             (v['doctor_name'] ?? '').toLowerCase().contains(q) ||
             (v['district'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.patientName,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('All Visit Records',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchVisits,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by facility, complaint, doctor...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Stats Row
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statChip('${_filtered.length} Visits', Colors.blue.shade700, Icons.list_alt),
                  const SizedBox(width: 8),
                  _statChip(
                    '${_visits.where((v) => (v['visit_type'] ?? '') == 'Emergency').length} Emergency',
                    Colors.red.shade700,
                    Icons.emergency,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : _filtered.isEmpty
                        ? const Center(child: Text('No records found', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _buildVisitCard(_filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Map visit) {
    final type = visit['visit_type'] ?? 'OPD';
    final isEmergency = type.toLowerCase() == 'emergency';
    final typeColor = isEmergency ? Colors.red : const Color(0xFF5C6BC0);
    final typeBg = isEmergency ? const Color(0xFFFFEBEE) : const Color(0xFFE8EAF6);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorVisitDetailScreen(visit: Map<String, dynamic>.from(visit))),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.local_hospital, size: 14, color: typeColor),
                    const SizedBox(width: 6),
                    Text(visit['facility_name'] ?? 'Facility',
                        style: TextStyle(fontWeight: FontWeight.bold, color: typeColor, fontSize: 13)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(type, style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location & date
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${visit['district'] ?? ''}, ${visit['state'] ?? ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDate(visit['created_at']),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chief Complaint
                  Text(visit['chief_complaint'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),

                  // Doctor
                  Row(children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${visit['doctor_name'] ?? 'Unknown Doctor'}  •  ${visit['specialization'] ?? 'General'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Vitals Row
                  _vitalsRow(visit),

                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('View full record', style: TextStyle(color: Color(0xFF5C6BC0), fontSize: 12)),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF5C6BC0)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalsRow(Map visit) {
    final temp = visit['temperature_c'];
    final bp = visit['bp'];
    final spo2 = visit['spo2'];

    if (temp == null && bp == null && spo2 == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (temp != null) _vitalChip('🌡️', '$temp°C', 'Temp'),
          if (bp != null) _vitalChip('💓', bp, 'BP'),
          if (spo2 != null) _vitalChip('🫁', '$spo2%', 'SpO2'),
        ],
      ),
    );
  }

  Widget _vitalChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return raw.split(' ').first;
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// DOCTOR VISIT DETAIL SCREEN — Full clinical data
// ─────────────────────────────────────────────────────────────────────────────

class DoctorVisitDetailScreen extends StatelessWidget {
  final Map<String, dynamic> visit;
  const DoctorVisitDetailScreen({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(
          visit['facility_name'] ?? 'Visit Details',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _section('🏥 Visit Overview', [
              _row('Visit Type', visit['visit_type']),
              _row('Facility', visit['facility_name']),
              _row('District', visit['district']),
              _row('State', visit['state']),
              _row('Date', _formatDate(visit['created_at'])),
            ]),
            const SizedBox(height: 14),
            _section('🩺 Clinical Details', [
              _row('Chief Complaint', visit['chief_complaint']),
              _row('Symptoms', visit['symptoms']),
              _row('Doctor', visit['doctor_name'] ?? 'Not specified'),
              _row('Specialization', visit['specialization'] ?? 'General'),
            ]),
            const SizedBox(height: 14),
            _section('📊 Vitals', [
              _row('Temperature', visit['temperature_c'] != null ? '${visit['temperature_c']}°C' : null),
              _row('Blood Pressure', visit['bp']),
              _row('SpO2', visit['spo2'] != null ? '${visit['spo2']}%' : null),
            ]),
            if (visit['vaccine_given'] == true) ...[
              const SizedBox(height: 14),
              _section('💉 Vaccination', [
                _row('Vaccine Name', visit['vaccine_name']),
                _row('Next Dose Due', visit['next_dose_due_date']),
              ]),
            ],
            if (visit['referred'] == true) ...[
              const SizedBox(height: 14),
              _section('↪️ Referral', [
                _row('Referred To', visit['referred_to']),
                _row('Reason', visit['referral_reason']),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5C6BC0))),
          const Divider(height: 18),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}
