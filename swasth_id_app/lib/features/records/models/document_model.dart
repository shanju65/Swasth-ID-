import 'package:flutter/material.dart';

enum RecordType { all, prescription, labReport, xray, scan, notes, other }

extension RecordTypeExtension on RecordType {
  String get displayName {
    switch (this) {
      case RecordType.all:
        return 'All';
      case RecordType.prescription:
        return 'Prescription';
      case RecordType.labReport:
        return 'Lab Report';
      case RecordType.xray:
        return 'X-Ray';
      case RecordType.scan:
        return 'Scan';
      case RecordType.notes:
        return 'Doctor Notes';
      case RecordType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordType.all:
        return Icons.list;
      case RecordType.prescription:
        return Icons.medication;
      case RecordType.labReport:
        return Icons.biotech;
      case RecordType.xray:
        return Icons.accessibility_new;
      case RecordType.scan:
        return Icons.scanner;
      case RecordType.notes:
        return Icons.note_alt;
      case RecordType.other:
        return Icons.insert_drive_file;
    }
  }
}

class DocumentModel {
  final String id;
  final String title;
  final RecordType type;
  final DateTime uploadDate;
  final String? doctorName;
  final String fileUrl; // Path, network URL, or local asset
  final bool isPdf;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.uploadDate,
    this.doctorName,
    required this.fileUrl,
    this.isPdf = false,
  });
}

class VisitGroup {
  final String visitId;
  final DateTime visitDate;
  final String diagnosis;
  final String doctorName;
  final List<DocumentModel> documents;
  
  // New Metadata Fields
  final String? symptoms;
  final double? temperature;
  final String? bp;
  final int? spo2;
  final String? visitType;
  final String? facilityName;
  final String? district;
  final String? state;
  final String? specialization;
  final bool vaccineGiven;
  final String? vaccineName;
  final String? nextDoseDate;
  final bool referred;
  final String? referredTo;
  final String? referralReason;

  VisitGroup({
    required this.visitId,
    required this.visitDate,
    required this.diagnosis,
    required this.doctorName,
    required this.documents,
    this.symptoms,
    this.temperature,
    this.bp,
    this.spo2,
    this.visitType,
    this.facilityName,
    this.district,
    this.state,
    this.specialization,
    this.vaccineGiven = false,
    this.vaccineName,
    this.nextDoseDate,
    this.referred = false,
    this.referredTo,
    this.referralReason,
  });
}
