import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';

class CreateVisitScreen extends StatefulWidget {
  final String healthId;
  const CreateVisitScreen({super.key, required this.healthId});

  @override
  State<CreateVisitScreen> createState() => _CreateVisitScreenState();
}

class _CreateVisitScreenState extends State<CreateVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Clinical Controllers
  final _facilityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _complaintController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _specializationController = TextEditingController(); 
  
  // Vitals
  final _tempController = TextEditingController();
  final _bpController = TextEditingController();
  final _spo2Controller = TextEditingController();
  
  // Vaccination
  bool _vaccineGiven = false;
  final _vaccineNameController = TextEditingController();
  final _vaccineDateController = TextEditingController();
  
  // Referral
  bool _referred = false;
  final _referredToController = TextEditingController();
  final _referralReasonController = TextEditingController();
  
  String _visitType = 'OPD';

  // Step 2: Documents
  final ImagePicker _picker = ImagePicker();
  XFile? _prescriptionFile;
  XFile? _labReportFile;
  XFile? _xrayFile;

  @override
  void dispose() {
    _facilityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _complaintController.dispose();
    _doctorNameController.dispose();
    _specializationController.dispose();
    _tempController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    _vaccineNameController.dispose();
    _vaccineDateController.dispose();
    _referredToController.dispose();
    _referralReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'Prescription') _prescriptionFile = image;
        if (type == 'Lab Report') _labReportFile = image;
        if (type == 'X-Ray') _xrayFile = image;
      });
    }
  }

  Future<void> _submitAll() async {
    setState(() => _isLoading = true);

    try {
      // 1. Create the Visit Record
      final result = await VisitService.createVisit(
        healthId: widget.healthId,
        facilityName: _facilityController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        visitType: _visitType,
        chiefComplaint: _complaintController.text.trim(),
        doctorName: _doctorNameController.text.trim().isNotEmpty ? _doctorNameController.text.trim() : null,
        specialization: _specializationController.text.trim().isNotEmpty ? _specializationController.text.trim() : null,
        temperature: double.tryParse(_tempController.text.trim()),
        bp: _bpController.text.trim().isEmpty ? null : _bpController.text.trim(),
        spo2: int.tryParse(_spo2Controller.text.trim()),
        vaccineGiven: _vaccineGiven,
        vaccineName: _vaccineGiven ? _vaccineNameController.text.trim() : null,
        nextDoseDate: _vaccineGiven ? _vaccineDateController.text.trim() : null,
        referred: _referred,
        referredTo: _referred ? _referredToController.text.trim() : null,
        referralReason: _referred ? _referralReasonController.text.trim() : null,
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'Failed to create visit');
      }

      final String visitId = result['data']['visit_id'];

      // 2. Sequentially Upload Documents
      if (_prescriptionFile != null) {
        await VisitService.uploadPrescription(visitId, _prescriptionFile!);
      }
      if (_labReportFile != null) {
        await VisitService.uploadPrescription(visitId, _labReportFile!);
      }
      if (_xrayFile != null) {
        await VisitService.uploadPrescription(visitId, _xrayFile!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record Created & Documents Uploaded Successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medical Record')),
      body: _isLoading 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating record and uploading documents...'),
              ],
            ))
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _currentStep++);
                  }
                } else {
                  _submitAll();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              steps: [
                Step(
                  title: const Text('Details'),
                  isActive: _currentStep >= 0,
                  content: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _facilityController,
                          decoration: const InputDecoration(labelText: 'Facility Name', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder()),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _visitType,
                          items: ['OPD', 'Emergency', 'Referral']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _visitType = v!),
                          decoration: const InputDecoration(labelText: 'Visit Type', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _complaintController,
                          decoration: const InputDecoration(labelText: 'Chief Complaint', border: OutlineInputBorder()),
                          maxLines: 3,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text('Provider', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _doctorNameController,
                          decoration: const InputDecoration(labelText: 'Doctor Name', hintText: 'e.g. Dr. Smith', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') return const Iterable<String>.empty();
                            const List<String> options = ['General Physician', 'Cardiologist', 'Dermatologist', 'Pediatrician', 'Orthopedist'];
                            return options.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String s) => _specializationController.text = s,
                          fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                            ctrl.text = _specializationController.text;
                            ctrl.addListener(() => _specializationController.text = ctrl.text);
                            return TextFormField(
                              controller: ctrl,
                              focusNode: focus,
                              decoration: const InputDecoration(labelText: 'Specialization', border: OutlineInputBorder()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('Vitals', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _tempController, decoration: const InputDecoration(labelText: 'Temp'), keyboardType: TextInputType.number)),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _bpController, decoration: const InputDecoration(labelText: 'BP'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _spo2Controller, decoration: const InputDecoration(labelText: 'SpO2'), keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(title: const Text('Vaccination?'), value: _vaccineGiven, onChanged: (v) => setState(() => _vaccineGiven = v)),
                        if (_vaccineGiven) ...[
                          TextFormField(controller: _vaccineNameController, decoration: const InputDecoration(labelText: 'Vaccine Name')),
                          TextFormField(controller: _vaccineDateController, decoration: const InputDecoration(labelText: 'Next Due (YYYY-MM-DD)')),
                        ],
                        SwitchListTile(title: const Text('Referred?'), value: _referred, onChanged: (v) => setState(() => _referred = v)),
                        if (_referred) ...[
                          TextFormField(controller: _referredToController, decoration: const InputDecoration(labelText: 'Referred To')),
                          TextFormField(controller: _referralReasonController, decoration: const InputDecoration(labelText: 'Reason')),
                        ],
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Documents'),
                  isActive: _currentStep >= 1,
                  content: Column(
                    children: [
                      const Text('Upload Medical Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _docCard('Prescription', _prescriptionFile, () => _pickImage('Prescription')),
                      const SizedBox(height: 12),
                      _docCard('Lab Report', _labReportFile, () => _pickImage('Lab Report')),
                      const SizedBox(height: 12),
                      _docCard('X-Ray / Scan', _xrayFile, () => _pickImage('X-Ray')),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _docCard(String title, XFile? file, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(file == null ? Icons.add_a_photo : Icons.check_circle, color: file == null ? Colors.grey : Colors.green),
        title: Text(title),
        subtitle: Text(file == null ? 'Not selected' : 'Selected: ${file.name}'),
        trailing: TextButton(onPressed: onTap, child: Text(file == null ? 'Add' : 'Change')),
      ),
    );
  }
}
