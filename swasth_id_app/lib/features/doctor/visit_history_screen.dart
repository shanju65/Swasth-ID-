import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/doctor/services/doctor_api_service.dart';
import 'package:swasth_id_app/features/doctor/add_visit_screen.dart';
import 'package:swasth_id_app/features/records/models/document_model.dart';
import 'package:swasth_id_app/features/records/screens/visit_details_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  final String healthId;
  final String patientName;

  const VisitHistoryScreen({
    super.key,
    required this.healthId,
    required this.patientName,
  });

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  List<dynamic> _visits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await DoctorApiService.getPatientVisits(widget.healthId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final raw = result['data'] as List? ?? [];
        // Sort newest first
        raw.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        _visits = raw;
      } else {
        _error = result['message']?.toString() ?? 'Failed to load visits';
      }
    });
  }

  // Convert raw visit Map → VisitGroup for reuse with VisitDetailsScreen
  VisitGroup _toVisitGroup(Map<String, dynamic> v) {
    return VisitGroup(
      visitId: v['visit_id']?.toString() ?? '',
      visitDate: DateTime.tryParse(v['created_at']?.toString() ?? '') ?? DateTime.now(),
      diagnosis: v['chief_complaint']?.toString() ?? 'Consultation',
      doctorName: v['doctor_name']?.toString() ?? 'Unknown',
      documents: const [],
      symptoms: v['symptoms']?.toString(),
      temperature: v['temperature_c'] != null ? double.tryParse(v['temperature_c'].toString()) : null,
      bp: v['bp']?.toString(),
      spo2: v['spo2'] != null ? int.tryParse(v['spo2'].toString()) : null,
      visitType: v['visit_type']?.toString(),
      facilityName: v['facility_name']?.toString(),
      district: v['district']?.toString(),
      state: v['state']?.toString(),
      specialization: v['specialization']?.toString(),
      vaccineGiven: v['vaccine_given'] == true,
      vaccineName: v['vaccine_name']?.toString(),
      nextDoseDate: v['next_dose_due_date']?.toString(),
      referred: v['referred'] == true,
      referredTo: v['referred_to']?.toString(),
      referralReason: v['referral_reason']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patientName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Visit History',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchVisits,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_visit_fab',
        onPressed: () async {
          final refreshed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddVisitScreen(
                healthId: widget.healthId,
                patientName: widget.patientName,
              ),
            ),
          );
          if (refreshed == true) _fetchVisits();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Visit'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _visits.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _fetchVisits,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        itemCount: _visits.length,
                        itemBuilder: (context, index) {
                          return _buildTimelineItem(context, index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, int index) {
    final visit = _visits[index];
    final isLast = index == _visits.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primaryColor.withOpacity(0.20),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: _buildVisitCard(context, visit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, dynamic visit) {
    final rawDate = visit['created_at']?.toString() ?? '';
    final date = rawDate.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(rawDate) ?? DateTime.now())
        : 'Unknown Date';
    final doctor = visit['doctor_name']?.toString() ?? 'Unknown Doctor';
    final spec = visit['specialization']?.toString() ?? 'General';
    final complaint = visit['chief_complaint']?.toString() ?? 'Consultation';
    final visitType = visit['visit_type']?.toString() ?? 'OPD';
    final facility = visit['facility_name']?.toString() ?? '';

    Color typeColor;
    switch (visitType.toLowerCase()) {
      case 'emergency':
        typeColor = AppColors.error;
        break;
      case 'referral':
        typeColor = AppColors.warning;
        break;
      default:
        typeColor = AppColors.primaryColor;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisitDetailsScreen(visit: _toVisitGroup(visit as Map<String, dynamic>)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: typeColor),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visitType,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chief complaint
                  Text(
                    complaint,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 8),
                  // Doctor
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.person, size: 16, color: AppColors.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. $doctor',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(spec, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  if (facility.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            facility,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Tap hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view full details',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No visits recorded for\n${widget.patientName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final refreshed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVisitScreen(
                    healthId: widget.healthId,
                    patientName: widget.patientName,
                  ),
                ),
              );
              if (refreshed == true) _fetchVisits();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add First Visit'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchVisits,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
