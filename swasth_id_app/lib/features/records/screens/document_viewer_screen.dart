import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';

class DocumentViewerScreen extends StatelessWidget {
  final DocumentModel document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing document...')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: document.isPdf
            ? _buildPdfViewer(context)
            : _buildImageViewer(),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 4.0,
      child: document.fileUrl.startsWith('http')
          ? Image.network(
              document.fileUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            )
          : (document.fileUrl.startsWith('assets')
              ? Image.asset(document.fileUrl)
              : Image.file(File(document.fileUrl))),
    );
  }

  Widget _buildPdfViewer(BuildContext context) {
    // Placeholder for PDF viewer until syncfusion_flutter_pdfviewer or similar is robustly added.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.picture_as_pdf, size: 100, color: Colors.redAccent),
        const SizedBox(height: 24),
        Text(
          'PDF Document: ${document.title}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF Viewing Module needs integration.')),
            );
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open PDF'),
        )
      ],
    );
  }
}
