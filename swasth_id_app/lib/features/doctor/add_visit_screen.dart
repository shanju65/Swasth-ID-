import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/doctor/services/doctor_api_service.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';

class AddVisitScreen extends StatefulWidget {
  final String healthId;
  final String patientName;

  const AddVisitScreen({
    super.key,
    required this.healthId,
    required this.patientName,
  });

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Doctor & Facility
  final _doctorNameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  // Clinical
  final _complaintCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();

  // Dropdowns / selectors
  String _visitType = 'OPD';
  String _severity = 'Mild';

  // Vaccination
  bool _vaccineGiven = false;
  final _vaccineNameCtrl = TextEditingController();
  final _vaccineDateCtrl = TextEditingController();

  // Referral
  bool _referred = false;
  final _referredToCtrl = TextEditingController();
  final _referralReasonCtrl = TextEditingController();

  // Attachments
  XFile? _prescriptionFile;
  XFile? _labReportFile;
  XFile? _xrayFile;
  final _picker = ImagePicker();

  bool _isLoading = false;

  static const _specializations = [
    'General Physician', 'Cardiologist', 'Dermatologist', 'Pediatrician',
    'Orthopedist', 'Gynecologist', 'Neurologist', 'Psychiatrist',
    'ENT Specialist', 'Dentist', 'Ophthalmologist', 'Pulmonologist',
  ];

  @override
  void dispose() {
    for (final c in [
      _doctorNameCtrl, _specializationCtrl, _facilityCtrl, _districtCtrl,
      _stateCtrl, _complaintCtrl, _symptomsCtrl, _notesCtrl, _tempCtrl,
      _bpCtrl, _spo2Ctrl, _vaccineNameCtrl, _vaccineDateCtrl,
      _referredToCtrl, _referralReasonCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        switch (type) {
          case 'prescription':
            _prescriptionFile = file;
            break;
          case 'lab':
            _labReportFile = file;
            break;
          case 'xray':
            _xrayFile = file;
            break;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await DoctorApiService.createVisit(
      healthId: widget.healthId,
      facilityName: _facilityCtrl.text.trim().isEmpty ? 'Not specified' : _facilityCtrl.text.trim(),
      district: _districtCtrl.text.trim().isEmpty ? 'Not specified' : _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? 'Not specified' : _stateCtrl.text.trim(),
      visitType: _visitType,
      chiefComplaint: _complaintCtrl.text.trim(),
      symptoms: _symptomsCtrl.text.trim().isNotEmpty ? _symptomsCtrl.text.trim() : null,
      temperature: double.tryParse(_tempCtrl.text.trim()),
      bp: _bpCtrl.text.trim().isNotEmpty ? _bpCtrl.text.trim() : null,
      spo2: int.tryParse(_spo2Ctrl.text.trim()),
      vaccineGiven: _vaccineGiven,
      vaccineName: _vaccineGiven ? _vaccineNameCtrl.text.trim() : null,
      nextDoseDate: _vaccineGiven ? _vaccineDateCtrl.text.trim() : null,
      referred: _referred,
      referredTo: _referred ? _referredToCtrl.text.trim() : null,
      referralReason: _referred ? _referralReasonCtrl.text.trim() : null,
      doctorName: _doctorNameCtrl.text.trim().isNotEmpty ? _doctorNameCtrl.text.trim() : null,
      specialization: _specializationCtrl.text.trim().isNotEmpty ? _specializationCtrl.text.trim() : null,
    );

    // Upload attachments if visit created successfully
    if (result['success'] == true) {
      final visitId = result['data']?['visit_id']?.toString();
      if (visitId != null) {
        for (final entry in [
          {'file': _prescriptionFile, 'type': 'prescription'},
          {'file': _labReportFile, 'type': 'lab_report'},
          {'file': _xrayFile, 'type': 'xray'},
        ]) {
          final file = entry['file'] as XFile?;
          if (file != null) {
            await VisitService.uploadPrescription(visitId, file);
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Visit recorded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true); // Signal caller to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed to create visit'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
            const Text('Add New Visit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              widget.patientName,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- DOCTOR INFO --
              _buildSectionHeader('Doctor & Facility', Icons.person_outlined, AppColors.primaryColor),
              _buildCard(children: [
                _buildField(_doctorNameCtrl, 'Doctor Name', hint: 'Dr. Name', icon: Icons.person, required: true),
                const SizedBox(height: 12),
                _buildAutocomplete(),
                const SizedBox(height: 12),
                _buildField(_facilityCtrl, 'Facility / Hospital', icon: Icons.local_hospital_outlined),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildField(_districtCtrl, 'District', icon: Icons.location_on_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_stateCtrl, 'State', icon: Icons.map_outlined)),
                ]),
              ]),

              const SizedBox(height: 16),

              // -- VISIT INFO --
              _buildSectionHeader('Visit Details', Icons.assignment_outlined, AppColors.tealAccent),
              _buildCard(children: [
                // Visit type
                _buildDropdownRow(),
                const SizedBox(height: 12),
                _buildTextArea(_complaintCtrl, 'Chief Complaint / Diagnosis *', required: true),
                const SizedBox(height: 12),
                _buildTextArea(_symptomsCtrl, 'Symptoms (optional)'),
                const SizedBox(height: 12),
                _buildTextArea(_notesCtrl, 'Clinical Notes (optional)', maxLines: 2),
                const SizedBox(height: 12),
                // Severity
                _buildSeveritySelector(),
              ]),

              const SizedBox(height: 16),

              // -- VITALS --
              _buildSectionHeader('Clinical Vitals', Icons.monitor_heart_outlined, Colors.redAccent),
              _buildCard(children: [
                Row(children: [
                  Expanded(child: _buildField(_tempCtrl, 'Temp (°C)', keyboard: TextInputType.number, icon: Icons.thermostat)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(_bpCtrl, 'BP (e.g. 120/80)', icon: Icons.compress)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(_spo2Ctrl, 'SpO2 (%)', keyboard: TextInputType.number, icon: Icons.bloodtype)),
                ]),
              ]),

              const SizedBox(height: 16),

              // -- ATTACHMENTS --
              _buildSectionHeader('Attachments', Icons.attach_file_rounded, Colors.deepPurple),
              _buildCard(children: [
                _AttachmentRow(
                  icon: Icons.description_outlined,
                  label: 'Prescription',
                  color: AppColors.primaryColor,
                  file: _prescriptionFile,
                  onTap: () => _pickFile('prescription'),
                  onRemove: () => setState(() => _prescriptionFile = null),
                ),
                const SizedBox(height: 10),
                _AttachmentRow(
                  icon: Icons.science_outlined,
                  label: 'Lab Report',
                  color: Colors.teal,
                  file: _labReportFile,
                  onTap: () => _pickFile('lab'),
                  onRemove: () => setState(() => _labReportFile = null),
                ),
                const SizedBox(height: 10),
                _AttachmentRow(
                  icon: Icons.photo_outlined,
                  label: 'X-Ray / Scan',
                  color: Colors.deepPurple,
                  file: _xrayFile,
                  onTap: () => _pickFile('xray'),
                  onRemove: () => setState(() => _xrayFile = null),
                ),
              ]),

              const SizedBox(height: 16),

              // -- VACCINATION --
              _buildSectionHeader('Vaccination', Icons.vaccines_outlined, Colors.green),
              _buildCard(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vaccine Administered?', style: TextStyle(fontSize: 14)),
                  value: _vaccineGiven,
                  onChanged: (v) => setState(() => _vaccineGiven = v),
                  activeColor: Colors.green,
                ),
                if (_vaccineGiven) ...[
                  const SizedBox(height: 8),
                  _buildField(_vaccineNameCtrl, 'Vaccine Name', icon: Icons.vaccines),
                  const SizedBox(height: 8),
                  _buildField(_vaccineDateCtrl, 'Next Dose Date (YYYY-MM-DD)', icon: Icons.event),
                ],
              ]),

              const SizedBox(height: 16),

              // -- REFERRAL --
              _buildSectionHeader('Referral', Icons.forward_outlined, AppColors.warning),
              _buildCard(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Patient Referred?', style: TextStyle(fontSize: 14)),
                  value: _referred,
                  onChanged: (v) => setState(() => _referred = v),
                  activeColor: AppColors.warning,
                ),
                if (_referred) ...[
                  const SizedBox(height: 8),
                  _buildField(_referredToCtrl, 'Referred To (Hospital/Doctor)', icon: Icons.local_hospital_outlined),
                  const SizedBox(height: 8),
                  _buildField(_referralReasonCtrl, 'Reason for Referral', icon: Icons.note_alt_outlined),
                ],
              ]),

              const SizedBox(height: 32),

              // SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Save Visit Record',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // -- HELPER BUILDERS --

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)),
        filled: true,
        fillColor: AppColors.backgroundColor,
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null : null,
    );
  }

  Widget _buildTextArea(TextEditingController ctrl, String label, {int maxLines = 3, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)),
        filled: true,
        fillColor: AppColors.backgroundColor,
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null : null,
    );
  }

  Widget _buildDropdownRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _visitType,
            decoration: InputDecoration(
              labelText: 'Visit Type',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              filled: true,
              fillColor: AppColors.backgroundColor,
            ),
            items: ['OPD', 'Emergency', 'Referral', 'Follow-up', 'Vaccination']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _visitType = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Severity', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: ['Mild', 'Moderate', 'Severe'].map((s) {
            Color chipColor;
            switch (s) {
              case 'Moderate': chipColor = AppColors.warning; break;
              case 'Severe': chipColor = AppColors.error; break;
              default: chipColor = AppColors.success;
            }
            final selected = _severity == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s, style: TextStyle(color: selected ? Colors.white : chipColor, fontWeight: FontWeight.bold, fontSize: 12)),
                selected: selected,
                onSelected: (_) => setState(() => _severity = s),
                selectedColor: chipColor,
                backgroundColor: chipColor.withOpacity(0.1),
                side: BorderSide(color: chipColor.withOpacity(0.4)),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const [];
        return _specializations.where(
          (s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (s) => _specializationCtrl.text = s,
      fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
        // keep controllers in sync
        controller.addListener(() => _specializationCtrl.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: 'Specialization',
            hintText: 'e.g. Cardiologist',
            prefixIcon: const Icon(Icons.workspace_premium_outlined, size: 18),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: AppColors.backgroundColor,
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// Attachment Row Widget
// --------------------------------------------------
class _AttachmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AttachmentRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.file,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? color.withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasFile ? color : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: hasFile ? color : Colors.grey.shade600, fontSize: 13)),
                  if (hasFile)
                    Text(
                      file!.name,
                      style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text('Tap to attach', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.grey,
                onPressed: onRemove,
              )
            else
              Icon(Icons.upload_file_outlined, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
