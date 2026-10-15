import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/records/create_visit_screen.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';
import 'package:swasth_id_app/features/records/visit_detail_screen.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ViewMode { list, calendar, timeline }

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  List<dynamic> _allVisits = [];
  List<dynamic> _filteredVisits = [];
  bool _isLoading = true;
  String? _healthId;
  String? _error;

  ViewMode _viewMode = ViewMode.list;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHealthIdAndVisits();
  }

  Future<void> _loadHealthIdAndVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHealthId = prefs.getString('health_id');
    
    if (storedHealthId != null) {
      _healthId = storedHealthId;
      _fetchVisits();
    } else {
      setState(() {
         _error = "Health ID not found. Return to Home."; 
         _isLoading = false;
      });
    }
  }

  Future<void> _fetchVisits() async {
    try {
      final visits = await VisitService.getVisits(_healthId!);
      
      setState(() {
        _allVisits = visits;
        _filteredVisits = visits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterVisits(String query) {
    if (query.isEmpty) {
        setState(() => _filteredVisits = _allVisits);
        return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredVisits = _allVisits.where((visit) {
        final facility = (visit['facility_name'] ?? '').toLowerCase();
        final doctor = (visit['doctor_name'] ?? '').toLowerCase();
        final type = (visit['visit_type'] ?? '').toLowerCase();
        return facility.contains(lowerQuery) || 
               doctor.contains(lowerQuery) || 
               type.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _generateAndSharePdf(dynamic visit) async {
      final pdf = pw.Document();
      
      final date = visit['created_at'] != null ? visit['created_at'].toString().split('T')[0] : 'Unknown Date';
      final doctor = visit['doctor_name'] ?? 'Unknown Doctor';
      final facility = visit['facility_name'] ?? 'Unknown Facility';
      final type = visit['visit_type'] ?? 'OPD';
      final complaint = visit['chief_complaint'] ?? 'N/A';
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                        pw.Text('Swasth ID Record', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(date, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ]
                  )
                ),
                pw.SizedBox(height: 20),
                
                pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                            pw.Text('Doctor: $doctor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                            pw.Text('Facility: $facility'),
                            pw.Text('Type: $type'),
                        ]
                    )
                ),
                pw.SizedBox(height: 20),
                pw.Text('Chief Complaint:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(complaint),
                pw.SizedBox(height: 10),
                
                if (visit['symptoms'] != null) ...[
                   pw.Text('Symptoms:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                   pw.Text(visit['symptoms']),
                   pw.SizedBox(height: 10),
                ],
                
                pw.Divider(),
                pw.Text('Generated by Swasth ID App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'swasth_record_$date.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
               // Generate Summary PDF logic could go here
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Generate Full Summary (Coming Soon)')),
               );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_healthId == null) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateVisitScreen(healthId: _healthId!),
            ),
          );
          if (result == true) {
            _fetchVisits();
          }
        },
        label: const Text('Add Record'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _filterVisits,
            decoration: InputDecoration(
              hintText: 'Search Doctor, Hospital...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // 2. View Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ViewMode>(
             segments: const [
               ButtonSegment(value: ViewMode.list, icon: Icon(Icons.list), label: Text("List")),
               ButtonSegment(value: ViewMode.calendar, icon: Icon(Icons.calendar_month), label: Text("Calendar")),
               ButtonSegment(value: ViewMode.timeline, icon: Icon(Icons.timeline), label: Text("Timeline")),
             ],
             selected: <ViewMode>{_viewMode},
             onSelectionChanged: (Set<ViewMode> newSelection) {
               setState(() => _viewMode = newSelection.first);
             },
             style: ButtonStyle(
               backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                 if (states.contains(MaterialState.selected)) return AppColors.primaryColor.withOpacity(0.2);
                 return Colors.white.withOpacity(0.5);
               }),
             ),
          ),
        ),
        
        const SizedBox(height: 10),

        // 3. Content
        Expanded(
          child: _visitsContent(),
        ),
      ],
    );
  }

  Widget _visitsContent() {
    if (_filteredVisits.isEmpty) {
      return const Center(child: Text("No records found"));
    }

    switch (_viewMode) {
      case ViewMode.list:
        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          itemCount: _filteredVisits.length,
          itemBuilder: (context, index) => _buildEnhancedVisitCard(_filteredVisits[index]),
        );
      case ViewMode.calendar:
        return _buildCalendarView(); 
      case ViewMode.timeline:
        return _buildTimelineView(); 
    }
  }

  // --- Calendar View Stub ---
  Widget _buildCalendarView() {
    // Simple 30-day grid for demo
    // In a real app, use table_calendar. Here we simulate a monthly view.
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Current Month", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              mainAxisSpacing: 8, 
              crossAxisSpacing: 8
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              final day = index + 1;
              // Check if any visit on this day (mock check for current month)
              // Be robust about date parsing
              final bool hasVisit = _filteredVisits.any((v) {
                   if (v['created_at'] == null) return false;
                   try {
                     final d = DateTime.parse(v['created_at']);
                     return d.day == day;
                   } catch (e) {
                     return false;
                   }
              });

              return Container(
                decoration: BoxDecoration(
                  color: hasVisit ? AppColors.primaryColor : Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  "$day", 
                  style: TextStyle(
                    color: hasVisit ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold
                  )
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Timeline View Stub ---
  Widget _buildTimelineView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: _filteredVisits.length,
      itemBuilder: (context, index) {
        final visit = _filteredVisits[index];
             
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Column(
                 children: [
                   Container(
                     width: 16, height: 16,
                     decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                   ),
                   Expanded(child: Container(width: 2, color: AppColors.primaryColor.withOpacity(0.3))),
                 ],
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.only(bottom: 24.0),
                   child: _buildEnhancedVisitCard(visit),
                 ),
               ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildEnhancedVisitCard(dynamic visit) {
    String date = 'Unknown Date';
    if (visit['created_at'] != null) {
        try {
            date = visit['created_at'].toString().split('T')[0];
        } catch (_) {}
    }
    
    final doctor = visit['doctor_name'] ?? 'Unknown Doctor';
    final spec = visit['specialization'] ?? 'General';
    final attachments = visit['attachments']; // String or JSON

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitDetailScreen(visit: visit),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: AppColors.primaryColor),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(color: AppColors.primaryColor.withOpacity(0.3))
                      ),
                      child: Text(visit['visit_type'] ?? 'OPD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Row
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18, 
                          backgroundColor: Colors.blueAccent, 
                          child: Icon(Icons.person, color: Colors.white, size: 20)
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(spec, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hospital Row
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                             visit['facility_name'] ?? 'Unknown Facility', 
                             style: const TextStyle(color: AppColors.textColor),
                             overflow: TextOverflow.ellipsis,
                          )
                        ),
                      ],
                    ),
                    
                    if (attachments != null && attachments.toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                         children: [
                           const Icon(Icons.attachment, size: 16, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text("Has Attachments", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                         ],
                      )
                    ]
                  ],
                ),
              ),
              
              // Share Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))
                ),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                        // Trigger PDF Generation
                        _generateAndSharePdf(visit);
                    },
                    icon: const Icon(Icons.share, size: 16, color: AppColors.primaryColor),
                    label: const Text("Share / Download PDF", style: TextStyle(color: AppColors.primaryColor)),
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
