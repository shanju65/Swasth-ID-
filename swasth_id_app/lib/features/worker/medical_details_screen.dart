import 'package:flutter/material.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:swasth_id_app/features/worker/id_upload_screen.dart';

class MedicalDetailsScreen extends StatefulWidget {
  final String mobile;
  final String? aadhaarNumber;
  const MedicalDetailsScreen({super.key, required this.mobile, this.aadhaarNumber});

  @override
  State<MedicalDetailsScreen> createState() => _MedicalDetailsScreenState();
}

class _MedicalDetailsScreenState extends State<MedicalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _vaccinationController = TextEditingController();
  final _allergiesController = TextEditingController();
  
  String _bloodGroup = 'O+';
  bool _isLoading = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final result = await ApiService.submitMedicalDetails(
      mobile: widget.mobile,
      height: double.tryParse(_heightController.text) ?? 0,
      weight: double.tryParse(_weightController.text) ?? 0,
      bloodGroup: _bloodGroup,
      vaccinationStatus: _vaccinationController.text.trim(),
      allergies: _allergiesController.text.trim(),
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IdUploadScreen(
            mobile: widget.mobile,
            aadhaarNumber: widget.aadhaarNumber,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step 2: Medical Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                items: _bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _bloodGroup = v!),
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _vaccinationController,
                decoration: const InputDecoration(
                  labelText: 'Vaccination Status',
                  hintText: 'e.g. Fully Vaccinated, 1 dose, None'
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'e.g. Peanuts, None'
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Next: ID Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
