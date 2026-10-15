import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/visit_service.dart';

class EditVisitSheet extends StatefulWidget {
  final VisitGroup visit;
  final VoidCallback onUpdated;

  const EditVisitSheet({super.key, required this.visit, required this.onUpdated});

  @override
  State<EditVisitSheet> createState() => _EditVisitSheetState();
}

class _EditVisitSheetState extends State<EditVisitSheet> {
  late TextEditingController _complaintController;
  late TextEditingController _tempController;
  late TextEditingController _bpController;
  late TextEditingController _spo2Controller;
  late TextEditingController _doctorController;
  late TextEditingController _specializationController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _complaintController = TextEditingController(text: widget.visit.diagnosis);
    _tempController = TextEditingController(text: widget.visit.temperature?.toString() ?? '');
    _bpController = TextEditingController(text: widget.visit.bp ?? '');
    _spo2Controller = TextEditingController(text: widget.visit.spo2?.toString() ?? '');
    _doctorController = TextEditingController(text: widget.visit.doctorName != '-' ? widget.visit.doctorName : '');
    _specializationController = TextEditingController(text: widget.visit.specialization ?? '');
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _tempController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    _doctorController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    try {
      final res = await VisitService.updateVisit(
        visitId: widget.visit.visitId,
        chiefComplaint: _complaintController.text,
        temperature: double.tryParse(_tempController.text),
        bp: _bpController.text,
        spo2: int.tryParse(_spo2Controller.text),
        doctorName: _doctorController.text,
        specialization: _specializationController.text,
      );

      if (res['success']) {
        widget.onUpdated();
        Navigator.pop(context);
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Visit Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildTextField(_complaintController, 'Chief Complaint', Icons.sick_outlined),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildTextField(_tempController, 'Temp (°C)', Icons.thermostat, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_spo2Controller, 'SpO2 (%)', Icons.bloodtype, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTextField(_bpController, 'Blood Pressure (e.g. 120/80)', Icons.compress),
            const SizedBox(height: 16),
            
            _buildTextField(_doctorController, 'Doctor Name', Icons.person_outline),
            const SizedBox(height: 16),
            
            _buildTextField(_specializationController, 'Specialization', Icons.workspace_premium_outlined),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
