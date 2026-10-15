import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';

class RecordPreviewScreen extends StatelessWidget {
  final String title;
  final String fileUrl;
  final bool isPdf;
  final String? recordType; // 'prescription', 'lab_report', 'xray', etc.

  const RecordPreviewScreen({
    super.key,
    required this.title,
    required this.fileUrl,
    this.isPdf = false,
    this.recordType,
  });

  IconData get _typeIcon {
    switch ((recordType ?? '').toLowerCase()) {
      case 'prescription': return Icons.description_outlined;
      case 'lab_report': return Icons.science_outlined;
      case 'xray': return Icons.photo_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color get _typeColor {
    switch ((recordType ?? '').toLowerCase()) {
      case 'prescription': return AppColors.primaryColor;
      case 'lab_report': return AppColors.tealAccent;
      case 'xray': return const Color(0xFF7C3AED);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            if (recordType != null)
              Text(
                recordType!.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 10, color: _typeColor, letterSpacing: 0.8),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing document...')),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: isPdf ? _buildPdfView(context) : _buildImageView(context),
    );
  }

  Widget _buildImageView(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: fileUrl.startsWith('http')
            ? Image.network(
                fileUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => _buildErrorState(context),
              )
            : fileUrl.startsWith('assets')
                ? Image.asset(fileUrl, fit: BoxFit.contain)
                : File(fileUrl).existsSync()
                    ? Image.file(File(fileUrl), fit: BoxFit.contain)
                    : _buildErrorState(context),
      ),
    );
  }

  Widget _buildPdfView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, size: 56, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'PDF Document',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF viewer integration required (syncfusion_flutter_pdfviewer)')),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open PDF', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_typeIcon, size: 64, color: _typeColor.withOpacity(0.5)),
        const SizedBox(height: 16),
        const Text(
          'Could not load document',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          fileUrl,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
