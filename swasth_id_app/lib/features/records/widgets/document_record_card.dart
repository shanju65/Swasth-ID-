import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';
import '../screens/document_viewer_screen.dart';

class DocumentRecordCard extends StatelessWidget {
  final DocumentModel document;

  const DocumentRecordCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentViewerScreen(document: document),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Preview Icon or Thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: document.isPdf
                    ? Icon(Icons.picture_as_pdf, color: Colors.red.shade400, size: 30)
                    : Icon(document.type.icon, color: theme.colorScheme.primary, size: 30),
              ),
              const SizedBox(width: 16),
              // Document Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(document.type.icon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          document.type.displayName,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(document.uploadDate),
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
