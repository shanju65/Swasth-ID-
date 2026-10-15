import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models/document_model.dart';
import 'document_record_card.dart';
import 'edit_visit_sheet.dart';
import '../screens/visit_details_screen.dart';
import '../services/pdf_service.dart';

class VisitTimelineCard extends StatelessWidget {
  final VisitGroup visit;
  final VoidCallback onRefresh;

  const VisitTimelineCard({
    super.key,
    required this.visit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = _getThemeColor(theme);

    return IntrinsicHeight(
      child: Row(
        children: [
          _buildTimelineIndicator(indicatorColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 20, top: 0),
              child: _buildGlassCard(context, theme, indicatorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(Color color) {
    return Container(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
          Expanded(
            child: Container(
              width: 3,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.5), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, ThemeData theme, Color indicatorColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(visit.visitDate),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionIcon(Icons.edit_outlined, () => _showEditSheet(context), color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        _buildActionIcon(Icons.picture_as_pdf_outlined, () => PdfService.generateAndShareVisitPdf(visit), color: Colors.blueGrey),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Info
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VisitDetailsScreen(visit: visit)),
                ).then((_) => onRefresh()),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              visit.facilityName ?? "Medical Consultation",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1C1E)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildVisitTypeTag(indicatorColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        visit.diagnosis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: indicatorColor.withOpacity(0.8),
                        ),
                      ),
                      if (visit.doctorName != '-') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Dr. ${visit.doctorName}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Quick Vitals Preview
              if (visit.temperature != null || visit.bp != null || visit.spo2 != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: indicatorColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      if (visit.temperature != null) _buildMiniVital(Icons.thermostat, '${visit.temperature}°C'),
                      if (visit.bp != null) _buildMiniVital(Icons.compress, visit.bp!),
                      if (visit.spo2 != null) _buildMiniVital(Icons.bloodtype, '${visit.spo2}%'),
                      const Spacer(),
                      if (visit.documents.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, size: 12, color: Colors.blueGrey),
                              const SizedBox(width: 2),
                              Text('${visit.documents.length}', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitTypeTag(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        visit.visitType ?? 'OPD',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap, {required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildMiniVital(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey[400]),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF42474E))),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditVisitSheet(
        visit: visit,
        onUpdated: onRefresh,
      ),
    );
  }

  Color _getThemeColor(ThemeData theme) {
    if (visit.visitType == 'Emergency') return const Color(0xFFBA1A1A);
    if (visit.visitType == 'OP') return const Color(0xFF006D39);
    return const Color(0xFF005AC1);
  }
}
