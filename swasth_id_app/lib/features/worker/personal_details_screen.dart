import 'package:flutter/material.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:swasth_id_app/features/worker/medical_details_screen.dart';
import 'package:swasth_id_app/widgets/aadhaar_scan_sheet.dart';
import 'package:swasth_id_app/services/ocr_aadhaar_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String mobile;
  const PersonalDetailsScreen({super.key, required this.mobile});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String _gender = 'Male';
  bool _isLoading = false;
  AadhaarOcrResult? _ocrResult; // Set after a successful scan

  Future<void> _scanAadhaar() async {
    final result = await AadhaarScanSheet.show(context);
    if (result == null || !result.success) return;

    setState(() {
      _ocrResult = result;
      // Auto-fill only non-empty extracted values
      if (result.name?.isNotEmpty == true) {
        _nameController.text = result.name!;
      }
      // Try to derive age from DOB string (DD/MM/YYYY or YYYY)
      if (result.dob?.isNotEmpty == true) {
        final dob = result.dob!;
        int? year;
        if (dob.length == 4) {
          year = int.tryParse(dob);
        } else {
          final parts = dob.split(RegExp(r'[/\-]'));
          if (parts.length == 3) year = int.tryParse(parts.last.length == 4 ? parts.last : parts.first);
        }
        if (year != null) {
          final age = DateTime.now().year - year;
          if (age > 0 && age < 120) _ageController.text = age.toString();
        }
      }
      // Auto-fill Gender
      if (result.gender?.isNotEmpty == true) {
        final g = result.gender!.trim().toLowerCase();
        if (g == 'male') {
          _gender = 'Male';
        } else if (g == 'female') {
          _gender = 'Female';
        } else if (g == 'other') {
          _gender = 'Other';
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final result = await ApiService.submitPersonalDetails(
      mobile: widget.mobile,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 0,
      gender: _gender,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalDetailsScreen(
            mobile: widget.mobile,
            aadhaarNumber: _ocrResult?.aadhaarNumber,
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
      appBar: AppBar(title: const Text('Step 1: Personal Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Scan Aadhaar Banner ──────────────────────────────────────
              _buildScanAadhaarBanner(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      items: ['Male', 'Female', 'Other']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                 controller: _stateController,
                 decoration: const InputDecoration(labelText: 'State'),
                 validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 6 ? '6 digits required' : null,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Next: Medical Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan Aadhaar banner ──────────────────────────────────────────────────
  Widget _buildScanAadhaarBanner() {
    final scanned = _ocrResult != null;
    return GestureDetector(
      onTap: _isLoading ? null : _scanAadhaar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: scanned
                ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
                : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (scanned
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF7C3AED))
                  .withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                scanned
                    ? Icons.check_circle_rounded
                    : Icons.document_scanner_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanned
                        ? 'Aadhaar Scanned Successfully'
                        : 'Scan Aadhaar Card',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scanned
                        ? 'Details auto-filled · Tap to re-scan'
                        : 'Auto-fill name & age from Aadhaar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
