import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';

class VisitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> visit;
  const VisitDetailScreen({super.key, required this.visit});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final _picker = ImagePicker();
  String? _ocrText;
  bool _isUploading = false;
  String? _uploadedImagePath;

  Future<void> _uploadPrescription() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() => _isUploading = true);

    // 1. Upload
    final uploadResult = await VisitService.uploadPrescription(
      widget.visit['visit_id'],
      picked,
    );

    if (uploadResult['success']) {
      final serverPath = uploadResult['data']['file_path'];
      setState(() => _uploadedImagePath = serverPath);

      // 2. Perform OCR
      final ocrResult = await VisitService.readOcrText(serverPath);
      
      setState(() {
        _ocrText = ocrResult;
        _isUploading = false;
      });
      
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uploadResult['message'])),
      );
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['facility_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Location: ${v['district']}, ${v['state']}'),
                    Text('Type: ${v['visit_type']}'),
                    Text('Date: ${v['created_at']}'),
                    const Divider(),
                    const Text('Chief Complaint:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(v['chief_complaint']),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Prescription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (_uploadedImagePath == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _uploadPrescription,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Upload Prescription'),
                ),
              )
            else
              const Card(
                color: Colors.greenAccent,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check),
                      SizedBox(width: 8),
                      Text('Prescription Uploaded'),
                    ],
                  ),
                ),
              ),
              
             if (_isUploading)
               const Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Center(child: CircularProgressIndicator()),
               ),
               
             if (_ocrText != null) ...[
               const SizedBox(height: 24),
               const Text('Extracted Text (OCR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   border: Border.all(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(_ocrText!),
               ),
             ]
          ],
        ),
      ),
    );
  }
}
