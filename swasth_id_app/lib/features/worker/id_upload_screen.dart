import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:swasth_id_app/features/worker/qr_screen.dart';

class IdUploadScreen extends StatefulWidget {
  final String mobile;
  final String? aadhaarNumber;
  const IdUploadScreen({super.key, required this.mobile, this.aadhaarNumber});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen> {
  final _picker = ImagePicker();
  
  String _idType = 'Aadhaar';
  XFile? _selectedFile;
  Uint8List? _fileBytes; // For Web display/upload
  
  // Confirmation form
  final _idNumberController = TextEditingController();
  bool _isUploading = false;
  bool _isVerifying = false;
  bool _isUploadComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.aadhaarNumber != null) {
      _idNumberController.text = widget.aadhaarNumber!;
      _isUploadComplete = true;
    }
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedFile = picked;
        _fileBytes = bytes;
        _isUploadComplete = false; // Reset if new image picked
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _fileBytes == null) return;
    
    setState(() => _isUploading = true);
    
    final result = await ApiService.uploadIdProof(
      mobile: widget.mobile,
      fileBytes: _fileBytes!,
      filename: _selectedFile!.name,
    );
    
    setState(() => _isUploading = false);
    
    if (result['success']) {
      setState(() => _isUploadComplete = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Uploaded. Please confirm details.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _confirmAndFinish() async {
    final idNum = _idNumberController.text.trim();
    if (idNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ID Number')),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    
    final result = await ApiService.confirmIdVerification(
      mobile: widget.mobile,
      idType: _idType,
      idNumber: idNum,
    );
    
    setState(() => _isVerifying = false);
    
    if (result['success']) {
      final healthId = result['data']['health_id'];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrScreen(
            mobile: widget.mobile,
            healthId: healthId,
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
      appBar: AppBar(title: const Text('Step 3: ID Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _idType,
              items: ['Aadhaar', 'Voter ID', 'Driving License']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _idType = v!),
              decoration: const InputDecoration(labelText: 'ID Type'),
            ),
            const SizedBox(height: 20),
            
            // Image Picker UI
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _fileBytes != null
                    ? Image.memory(_fileBytes!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          Text('Tap to select ID Photo'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Disable upload if already uploaded or no file
                onPressed: (_isUploading || _fileBytes == null || _isUploadComplete)
                    ? null 
                    : _uploadFile,
                icon: const Icon(Icons.cloud_upload),
                label: _isUploading 
                   ? const Text('Uploading...') 
                   : Text(_isUploadComplete ? 'Uploaded' : 'Upload ID Proof'),
              ),
            ),
            
            const Divider(height: 40),
            
            // Confirmation UI
            if (_isUploadComplete) ...[
              const Text(
                'Confirm Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idNumberController,
                decoration: const InputDecoration(
                  labelText: 'Enter ID Number',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the number manually to confirm',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isVerifying ? null : _confirmAndFinish,
                  child: _isVerifying 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('COMPLETE REGISTRATION'),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
