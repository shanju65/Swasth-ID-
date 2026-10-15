import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/document_model.dart';
import '../services/records_api_service.dart';
import '../services/visit_service.dart';
import '../services/pdf_service.dart';
import '../widgets/document_record_card.dart';
import '../widgets/edit_visit_sheet.dart';

class VisitDetailsScreen extends StatefulWidget {
  final VisitGroup visit;

  const VisitDetailsScreen({super.key, required this.visit});

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  late VisitGroup _currentVisit;
  bool _isLoading = false;
  final RecordsApiService _apiService = RecordsApiService();

  @override
  void initState() {
    super.initState();
    _currentVisit = widget.visit;
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditVisitSheet(
        visit: _currentVisit,
        onUpdated: () {
          // In a more robust app, we'd trigger a re-fetch or use a provider.
          // For now, we inform the user it was updated.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit updated successfully!')));
        },
      ),
    );
  }

  Future<void> _addAttachment() async {
    // Basic modal to select document type then pick file
    final RecordType? selectedType = await showDialog<RecordType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [RecordType.prescription, RecordType.labReport, RecordType.xray, RecordType.scan, RecordType.other].map((t) {
            return ListTile(
              leading: Icon(t.icon),
              title: Text(t.displayName),
              onTap: () => Navigator.pop(context, t),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedType == null) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, picked?.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, picked?.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Document'),
              onTap: () async {
                final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                Navigator.pop(context, res?.files.single.path);
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final success = await _apiService.uploadMedicalRecord(
          healthId: 'H-DEFAULT-123', // In real app, get from prefs
          visitId: _currentVisit.visitId,
          documentType: selectedType.name,
          filePath: result,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment added successfully!')));
          // Normally we'd re-fetch the visit here to update the list.
          // For now, we inform the user to refresh the timeline.
          Navigator.pop(context, true); 
        } else {
          throw Exception("Upload failed");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visit = _currentVisit;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Visit Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditSheet,
            tooltip: 'Edit Record',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => PdfService.generateAndShareVisitPdf(visit),
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(theme, visit),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(visit),
                      const SizedBox(height: 16),
                      _buildVitalsCard(visit),
                      const SizedBox(height: 16),
                      if (visit.vaccineGiven) _buildVaccineCard(visit),
                      if (visit.referred) _buildReferralCard(visit),
                      const SizedBox(height: 16),
                      _buildAttachmentsSection(visit),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAttachment,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Add Attachment'),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, VisitGroup visit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMMM yyyy').format(visit.visitDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  visit.visitType ?? 'Consultation',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            visit.facilityName ?? 'Unknown Facility',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(VisitGroup visit) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Chief Complaint', visit.diagnosis, icon: Icons.sick_outlined, isBold: true),
            if (visit.symptoms != null) ...[
              const Divider(height: 24),
              _buildRow('Symptoms', visit.symptoms!, icon: Icons.description_outlined),
            ],
            const Divider(height: 24),
            _buildRow('Doctor', visit.doctorName != '-' ? 'Dr. ${visit.doctorName}' : 'Not Specified', icon: Icons.person_outline),
            if (visit.specialization != null)
              _buildRow('Specialization', visit.specialization!, icon: Icons.workspace_premium_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard(VisitGroup visit) {
    if (visit.temperature == null && visit.bp == null && visit.spo2 == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Clinical Vitals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (visit.temperature != null) _buildVitalDetail('Temp', '${visit.temperature}°C', Icons.thermostat, Colors.orange),
                if (visit.bp != null) _buildVitalDetail('BP', visit.bp!, Icons.compress, Colors.red),
                if (visit.spo2 != null) _buildVitalDetail('SpO2', '${visit.spo2}%', Icons.bloodtype, Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalDetail(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVaccineCard(VisitGroup visit) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: Colors.green[50],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.green[100]!)),
        child: ListTile(
          leading: const Icon(Icons.vaccines, color: Colors.green),
          title: Text('Vaccine Administered: ${visit.vaccineName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: visit.nextDoseDate != null ? Text('Next dose due: ${visit.nextDoseDate}') : null,
        ),
      ),
    );
  }

  Widget _buildReferralCard(VisitGroup visit) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: Colors.orange[50],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange[100]!)),
        child: ListTile(
          leading: const Icon(Icons.forward, color: Colors.orange),
          title: Text('Referred to: ${visit.referredTo ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Reason: ${visit.referralReason ?? "N/A"}'),
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(VisitGroup visit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attachments (${visit.documents.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ],
          ),
        ),
        if (visit.documents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.attachment_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  const Text('No documents attached to this visit', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...visit.documents.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DocumentRecordCard(document: doc),
              )),
      ],
    );
  }

  Widget _buildRow(String label, String value, {required IconData icon, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ],
    );
  }
}
