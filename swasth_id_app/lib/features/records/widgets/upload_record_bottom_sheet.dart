import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';
import '../services/records_api_service.dart';
import '../services/visit_service.dart';

class UploadRecordBottomSheet extends StatefulWidget {
  const UploadRecordBottomSheet({super.key});

  @override
  State<UploadRecordBottomSheet> createState() => _UploadRecordBottomSheetState();
}

class _UploadRecordBottomSheetState extends State<UploadRecordBottomSheet> {
  int _currentStep = 1; // 1: Visit Details, 2: Document Selection
  int _detailPage = 0;  // 0: Basic, 1: Vitals, 2: Pro/Referral
  bool _isProcessing = false;
  String? _createdVisitId;

  // Visit Detail Controllers - Basic
  final _facilityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _complaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  String _visitType = 'Consultation';

  // Vitals
  final _tempController = TextEditingController();
  final _bpController = TextEditingController();
  final _spo2Controller = TextEditingController();

  // Provider
  final _doctorController = TextEditingController();
  final _specController = TextEditingController();

  // Vaccination
  bool _vaccineGiven = false;
  final _vaccineNameController = TextEditingController();
  final _nextDoseController = TextEditingController();

  // Referral
  bool _referred = false;
  final _referredToController = TextEditingController();
  final _referralReasonController = TextEditingController();

  // Document selection
  RecordType _selectedType = RecordType.prescription;
  
  final RecordsApiService _apiService = RecordsApiService();

  @override
  void dispose() {
    _facilityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _complaintController.dispose();
    _symptomsController.dispose();
    _tempController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    _doctorController.dispose();
    _specController.dispose();
    _vaccineNameController.dispose();
    _nextDoseController.dispose();
    _referredToController.dispose();
    _referralReasonController.dispose();
    super.dispose();
  }

  Future<String?> _getHealthId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('health_id') ?? 'H-DEFAULT-123';
  }

  Future<void> _createVisit() async {
    if (_facilityController.text.isEmpty || 
        _districtController.text.isEmpty || 
        _stateController.text.isEmpty || 
        _complaintController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill mandatory fields in Step 1')),
      );
      setState(() => _detailPage = 0);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final healthId = await _getHealthId();
      if (healthId == null) throw Exception("Health ID not found");

      final result = await VisitService.createVisit(
        healthId: healthId,
        facilityName: _facilityController.text,
        district: _districtController.text,
        state: _stateController.text,
        visitType: _visitType,
        chiefComplaint: _complaintController.text,
        symptoms: _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
        temperature: double.tryParse(_tempController.text),
        bp: _bpController.text.isNotEmpty ? _bpController.text : null,
        spo2: int.tryParse(_spo2Controller.text),
        vaccineGiven: _vaccineGiven,
        vaccineName: _vaccineNameController.text.isNotEmpty ? _vaccineNameController.text : null,
        nextDoseDate: _nextDoseController.text.isNotEmpty ? _nextDoseController.text : null,
        referred: _referred,
        referredTo: _referredToController.text.isNotEmpty ? _referredToController.text : null,
        referralReason: _referralReasonController.text.isNotEmpty ? _referralReasonController.text : null,
        doctorName: _doctorController.text.isNotEmpty ? _doctorController.text : null,
        specialization: _specController.text.isNotEmpty ? _specController.text : null,
      );

      if (result['success'] == true) {
        final visitData = result['data'];
        _createdVisitId = visitData['id']?.toString() ?? visitData['visit_id']?.toString();
        
        setState(() {
          _currentStep = 2;
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to create visit');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUpload(String filePath) async {
    setState(() => _isProcessing = true);
    try {
      final healthId = await _getHealthId();
      
      final success = await _apiService.uploadMedicalRecord(
        healthId: healthId!,
        visitId: _createdVisitId,
        documentType: _selectedType.name,
        filePath: filePath,
      );

      if (success && mounted) {
        Navigator.pop(context, true); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload record.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) await _handleUpload(pickedFile.path);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) await _handleUpload(result.files.single.path!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isProcessing
              ? _buildLoadingState()
              : _currentStep == 1 
                  ? _buildVisitDetailsStep() 
                  : _buildDocumentSelectionStep(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildVisitDetailsStep() {
    return Column(
      key: ValueKey('step1_$_detailPage'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Visit Details (${_detailPage + 1}/3)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 16),
        if (_detailPage == 0) _buildBasicInfoPage(),
        if (_detailPage == 1) _buildVitalsPage(),
        if (_detailPage == 2) _buildProviderReferralPage(),
        const SizedBox(height: 24),
        Row(
          children: [
            if (_detailPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _detailPage--),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Back'),
                ),
              ),
            if (_detailPage > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _detailPage < 2 ? () => setState(() => _detailPage++) : _createVisit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(_detailPage < 2 ? 'Continue' : 'Next: Upload Documents'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoPage() {
    return Column(
      children: [
        _buildTextField(_facilityController, 'Facility Name *', Icons.local_hospital),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_districtController, 'District *', Icons.location_city)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_stateController, 'State *', Icons.map)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _visitType,
          decoration: const InputDecoration(labelText: 'Visit Type', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
          items: ['Consultation', 'OP', 'IP', 'Emergency', 'Checkup'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _visitType = v!),
        ),
        const SizedBox(height: 12),
        _buildTextField(_complaintController, 'Chief Complaint *', Icons.edit_note),
        const SizedBox(height: 12),
        _buildTextField(_symptomsController, 'Additional Symptoms', Icons.sick, maxLines: 2),
      ],
    );
  }

  Widget _buildVitalsPage() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField(_tempController, 'Temp (°C)', Icons.thermostat, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_spo2Controller, 'SpO2 (%)', Icons.bloodtype, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(_bpController, 'Blood Pressure (e.g. 120/80)', Icons.compress),
        const SizedBox(height: 24),
        const Divider(),
        SwitchListTile(
          title: const Text('Vaccine Given?'),
          value: _vaccineGiven,
          onChanged: (val) => setState(() => _vaccineGiven = val),
        ),
        if (_vaccineGiven) ...[
          _buildTextField(_vaccineNameController, 'Vaccine Name', Icons.vaccines),
          const SizedBox(height: 12),
          _buildTextField(_nextDoseController, 'Next Dose Date (YYYY-MM-DD)', Icons.calendar_today),
        ],
      ],
    );
  }

  Widget _buildProviderReferralPage() {
    return Column(
      children: [
        _buildTextField(_doctorController, 'Doctor Name', Icons.person),
        const SizedBox(height: 12),
        _buildTextField(_specController, 'Specialization', Icons.workspace_premium),
        const SizedBox(height: 24),
        const Divider(),
        SwitchListTile(
          title: const Text('Referred to another facility?'),
          value: _referred,
          onChanged: (val) => setState(() => _referred = val),
        ),
        if (_referred) ...[
          _buildTextField(_referredToController, 'Referred To', Icons.forward),
          const SizedBox(height: 12),
          _buildTextField(_referralReasonController, 'Reason for Referral', Icons.comment),
        ],
      ],
    );
  }

  Widget _buildDocumentSelectionStep() {
    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Upload Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('For: ${_facilityController.text}', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        DropdownButtonFormField<RecordType>(
          value: _selectedType,
          decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder()),
          items: [RecordType.prescription, RecordType.labReport, RecordType.xray, RecordType.scan, RecordType.notes, RecordType.other].map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _UploadOption(icon: Icons.camera_alt, label: 'Camera', onTap: () => _pickImage(ImageSource.camera)),
            _UploadOption(icon: Icons.image, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery)),
            _UploadOption(icon: Icons.picture_as_pdf, label: 'PDF', onTap: () => _pickPdf()),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finish (Show record in timeline)')),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
