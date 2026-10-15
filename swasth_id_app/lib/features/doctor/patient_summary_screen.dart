import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/doctor/services/doctor_api_service.dart';
import 'package:swasth_id_app/features/doctor/visit_history_screen.dart';
import 'package:swasth_id_app/features/doctor/add_visit_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class PatientSummaryScreen extends StatefulWidget {
  final String healthId;
  const PatientSummaryScreen({super.key, required this.healthId});

  @override
  State<PatientSummaryScreen> createState() => _PatientSummaryScreenState();
}

class _PatientSummaryScreenState extends State<PatientSummaryScreen> {
  bool _isLoading = true;
  String? _error;

  // AI Summary independent state
  bool _aiIsLoading = false;
  String? _aiError;
  bool _aiExpanded = true;

  Map<String, dynamic> _personal = {};
  Map<String, dynamic> _medical = {};
  List<dynamic> _visits = [];
  Map<String, dynamic> _aiSummary = {};

  // Vitals Trend Data
  List<FlSpot> _tempSpots = [];
  List<FlSpot> _spo2Spots = [];
  List<FlSpot> _bpSpots = [];
  List<String> _visitDateLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ---------------------------------------------------------------------------
  // Realistic mock returned when the backend endpoint is not yet live
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _buildMockSummary() {
    // Derive basic info from profile if already loaded, else use sensible defaults
    final allergy = (_medical['allergies']?.toString() ?? '').isNotEmpty &&
            (_medical['allergies']?.toString().toLowerCase() ?? '') != 'none'
        ? _medical['allergies'].toString()
        : 'None reported';
    final lastComplaint = _visits.isNotEmpty
        ? (_visits.first['chief_complaint'] ?? 'Consultation').toString()
        : 'No visits recorded yet';
    final lastDoctor = _visits.isNotEmpty
        ? (_visits.first['doctor_name'] ?? 'Unknown Doctor').toString()
        : '';
    final lastDate = _visits.isNotEmpty
        ? (_visits.first['created_at']?.toString().split('T')[0] ?? '')
        : '';

    return {
      'chronic_conditions': ['Asthma', 'Hypertension'],
      'recent_illness': ['Viral Fever (Feb 2026)', 'Upper Respiratory Infection (Jan 2026)'],
      'recent_tests': ['Blood Test (CBC)', 'Chest X-Ray', 'SpO2 Monitoring'],
      'allergies': allergy == 'None reported' ? ['None reported'] : allergy.split(',').map((e) => e.trim()).toList(),
      'last_visit_summary': lastDoctor.isNotEmpty
          ? 'Patient visited on $lastDate with complaint: $lastComplaint. Seen by Dr. $lastDoctor.'
          : lastComplaint,
      'source': 'mock',
    };
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Parallel fetch: profile + visits
    final results = await Future.wait([
      DoctorApiService.getPatientProfile(widget.healthId),
      DoctorApiService.getPatientVisits(widget.healthId),
    ]);

    final profileResult = results[0];
    final visitsResult = results[1];

    if (!mounted) return;

    if (!profileResult['success']) {
      setState(() {
        _isLoading = false;
        _error = profileResult['message'] ?? 'Failed to load patient data';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      final data = profileResult['data'] as Map<String, dynamic>;
      _personal = data['personal_details'] ?? {};
      _medical = data['medical_details'] ?? {};
      _visits = (visitsResult['data'] as List?) ?? [];
      _computeAnalytics();
    });

    // Fetch AI summary independently so profile renders immediately
    await _fetchAiSummary();
  }

  void _computeAnalytics() {
    _tempSpots = [];
    _spo2Spots = [];
    _bpSpots = [];
    _visitDateLabels = [];

    if (_visits.isEmpty) return;

    // Sort visits by date (oldest to newest for trend)
    final sorted = [..._visits]..sort((a, b) {
        try {
          return DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at']));
        } catch (_) {
          return 0;
        }
      });

    for (int i = 0; i < sorted.length; i++) {
      final v = sorted[i];
      _visitDateLabels.add(_shortDate(v['created_at']));

      final temp = _toDouble(v['temperature_c']);
      final spo2 = _toDouble(v['spo2']);
      final bp = _parseSystolic(v['bp']);

      if (temp != null) _tempSpots.add(FlSpot(i.toDouble(), temp));
      if (spo2 != null) _spo2Spots.add(FlSpot(i.toDouble(), spo2));
      if (bp != null) _bpSpots.add(FlSpot(i.toDouble(), bp));
    }
  }

  double? _toDouble(dynamic val) {
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  double? _parseSystolic(dynamic bp) {
    if (bp == null) return null;
    final str = bp.toString();
    final parts = str.split('/');
    return double.tryParse(parts[0].trim());
  }

  String _shortDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _fetchAiSummary() async {
    if (!mounted) return;
    setState(() {
      _aiIsLoading = true;
      _aiError = null;
    });

    try {
      final aiResult = await DoctorApiService.getPatientSummary(widget.healthId);
      if (!mounted) return;

      if (aiResult['success'] == true && aiResult['data'] != null) {
        setState(() {
          _aiSummary = Map<String, dynamic>.from(aiResult['data']);
          _aiIsLoading = false;
        });
      } else {
        // Backend not live yet — use rich local mock
        setState(() {
          _aiSummary = _buildMockSummary();
          _aiIsLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiSummary = _buildMockSummary();
        _aiIsLoading = false;
      });
    }
  }

  String get _patientName => (_personal['name'] ?? 'Patient').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoading ? 'Loading...' : _patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Health ID: ${widget.healthId.length > 8 ? widget.healthId.substring(0, 8) + '...' : widget.healthId}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPatientSnapshot(),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 16),
                        _buildAiSummaryCard(),
                        const SizedBox(height: 16),
                        _buildHealthAnalyticsDashboard(),
                        const SizedBox(height: 16),
                        _buildViewTimelineButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SECTION 1 — Patient Snapshot
  // --------------------------------------------------
  Widget _buildPatientSnapshot() {
    return _SectionCard(
      title: 'PATIENT SNAPSHOT',
      icon: Icons.person_pin_outlined,
      iconColor: AppColors.primaryColor,
      child: Column(
        children: [
          // Avatar + Name header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    Text(
                      '${_personal['age'] ?? '-'} yrs • ${_personal['gender'] ?? '-'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Medical chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthChip(
                label: _medical['blood_group'] ?? 'N/A',
                icon: Icons.bloodtype,
                color: Colors.red,
              ),
              _HealthChip(
                label: 'BMI ${_medical['bmi'] ?? '-'}',
                icon: Icons.monitor_weight_outlined,
                color: Colors.orange,
              ),
              _HealthChip(
                label: _medical['vaccination_status'] ?? 'N/A',
                icon: Icons.vaccines,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info rows
          _InfoRow(label: 'Height', value: '${_medical['height_cm'] ?? '-'} cm'),
          _InfoRow(label: 'Weight', value: '${_medical['weight_kg'] ?? '-'} kg'),
          _InfoRow(
            label: 'Allergies',
            value: _medical['allergies']?.toString().isNotEmpty == true
                ? _medical['allergies'].toString()
                : 'None reported',
            isAlert: (_medical['allergies']?.toString() ?? 'none').toLowerCase() != 'none' &&
                (_medical['allergies']?.toString() ?? '').isNotEmpty,
          ),
          _InfoRow(label: 'Address', value: '${_personal['city'] ?? '-'}, ${_personal['state'] ?? '-'}'),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SECTION 2 — Quick Actions
  // --------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.history_rounded,
            label: 'Visit History',
            color: AppColors.primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VisitHistoryScreen(
                  healthId: widget.healthId,
                  patientName: _patientName,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add Visit',
            color: AppColors.tealAccent,
            onTap: () async {
              final refreshed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddVisitScreen(
                    healthId: widget.healthId,
                    patientName: _patientName,
                  ),
                ),
              );
              if (refreshed == true) _fetchAll();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.folder_open_rounded,
            label: 'Records',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VisitHistoryScreen(
                  healthId: widget.healthId,
                  patientName: _patientName,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SECTION 3 — AI Medical Summary
  // --------------------------------------------------
  Widget _buildAiSummaryCard() {
    const purple = Color(0xFF7C3AED);
    const purpleSoft = Color(0xFFF3EEFF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _aiExpanded,
          onExpansionChanged: (v) => setState(() => _aiExpanded = v),
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: purpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: purple, size: 18),
          ),
          title: const Text(
            'AI MEDICAL SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: purple,
              letterSpacing: 0.8,
            ),
          ),
          subtitle: _aiSummary['source'] == 'mock'
              ? const Text(
                  'Simulated · Backend endpoint pending',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: purpleSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI Powered',
                  style: TextStyle(
                    fontSize: 10,
                    color: purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _aiExpanded ? Icons.expand_less : Icons.expand_more,
                color: purple,
                size: 20,
              ),
            ],
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: _aiIsLoading
                  ? _buildAiLoadingShimmer()
                  : _aiError != null
                      ? _buildAiErrorState()
                      : _buildAiContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Loading skeleton for AI section
  Widget _buildAiLoadingShimmer() {
    return Column(
      children: List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  // Error state with retry
  Widget _buildAiErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            _aiError ?? 'Could not load AI summary',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchAiSummary,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }

  // Fully rendered AI content
  Widget _buildAiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiSummaryRow(
          icon: Icons.favorite_border_rounded,
          iconColor: const Color(0xFFDC2626),
          label: 'Chronic Conditions',
          chipColor: const Color(0xFFDC2626),
          chipBg: const Color(0xFFFEF2F2),
          items: _toStringList(_aiSummary['chronic_conditions']),
        ),
        const Divider(height: 24),
        _AiSummaryRow(
          icon: Icons.sick_outlined,
          iconColor: const Color(0xFFD97706),
          label: 'Recent Illnesses',
          chipColor: const Color(0xFFD97706),
          chipBg: const Color(0xFFFFFBEB),
          items: _toStringList(_aiSummary['recent_illness']),
        ),
        const Divider(height: 24),
        _AiSummaryRow(
          icon: Icons.biotech_outlined,
          iconColor: const Color(0xFF0284C7),
          label: 'Recent Tests',
          chipColor: const Color(0xFF0284C7),
          chipBg: const Color(0xFFE0F2FE),
          items: _toStringList(_aiSummary['recent_tests']),
        ),
        const Divider(height: 24),
        _AiSummaryRow(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFF7C3AED),
          label: 'Allergies',
          chipColor: const Color(0xFF7C3AED),
          chipBg: const Color(0xFFF3EEFF),
          items: _toStringList(_aiSummary['allergies']),
        ),
        const Divider(height: 24),
        // Last Visit Summary — prose block
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.summarize_outlined, size: 16, color: Color(0xFF16A34A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Visit Summary',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
                    ),
                    child: Text(
                      _aiSummary['last_visit_summary']?.toString() ?? 'No summary available.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // Safely normalise dynamic field to List<String>
  List<String> _toStringList(dynamic raw) {
    if (raw == null) return ['—'];
    if (raw is List) {
      final items = raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      return items.isEmpty ? ['—'] : items;
    }
    final s = raw.toString().trim();
    return s.isEmpty ? ['—'] : [s];
  }

  // --------------------------------------------------
  // HEALTH ANALYTICS DASHBOARD
  // --------------------------------------------------
  bool get _hasSufficientData => _visits.length >= 2 && (_tempSpots.isNotEmpty || _spo2Spots.isNotEmpty || _bpSpots.isNotEmpty);

  Widget _buildHealthAnalyticsDashboard() {
    return _SectionCard(
      title: 'HEALTH ANALYTICS DASHBOARD',
      icon: Icons.analytics_outlined,
      iconColor: Colors.orange.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasSufficientData)
            _buildEmptyAnalyticsCard()
          else ...[
            if (_tempSpots.isNotEmpty) ...[
              _chartCard(
                title: '🌡️ Temperature Trend (°C)',
                subtitle: 'Normal: 36.1 – 37.2°C | Fever: > 38.5°C',
                chart: _lineChart(
                  spots: _tempSpots,
                  color: Colors.orange,
                  minY: 35,
                  maxY: 42,
                  dangerLine: 38.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_spo2Spots.isNotEmpty) ...[
              _chartCard(
                title: '🫁 SpO₂ Trend (%)',
                subtitle: 'Normal: ≥ 95% | Danger: < 95%',
                chart: _lineChart(
                  spots: _spo2Spots,
                  color: Colors.blue,
                  minY: 80,
                  maxY: 100,
                  dangerLine: 95,
                  dangerBelow: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_bpSpots.isNotEmpty) ...[
              _chartCard(
                title: '💓 Blood Pressure Trend (Systolic mmHg)',
                subtitle: 'Normal: < 120 mmHg | Hypertension: > 140',
                chart: _lineChart(
                  spots: _bpSpots,
                  color: Colors.red.shade400,
                  minY: 60,
                  maxY: 200,
                  dangerLine: 140,
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyAnalyticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No sufficient health records available for trend analysis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget chart}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textColor)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _lineChart({
    required List<FlSpot> spots,
    required Color color,
    required double minY,
    required double maxY,
    double? dangerLine,
    bool dangerBelow = false,
  }) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) => Text(value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _visitDateLabels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_visitDateLabels[idx], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: dangerLine != null
            ? ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: dangerLine,
                  color: Colors.red.withOpacity(0.5),
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: dangerBelow ? Alignment.bottomRight : Alignment.topRight,
                    labelResolver: (_) => dangerBelow ? 'Min safe' : 'Danger',
                    style: const TextStyle(fontSize: 9, color: Colors.red),
                  ),
                ),
              ])
            : null,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final isAbnormal = dangerBelow
                    ? (dangerLine != null && spot.y < dangerLine)
                    : (dangerLine != null && spot.y > dangerLine);
                return FlDotCirclePainter(
                  radius: 4,
                  color: isAbnormal ? Colors.red : color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTimelineButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisitHistoryScreen(
              healthId: widget.healthId,
              patientName: _patientName,
            ),
          ),
        ),
        icon: const Icon(Icons.timeline_rounded, color: Colors.white),
        label: const Text('View Full Medical Timeline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// REUSABLE LOCAL WIDGETS
// ===========================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _InfoRow({required this.label, required this.value, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isAlert ? AppColors.error : AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HealthChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Summary Row — renders label + list of color-coded chips
// ---------------------------------------------------------------------------
class _AiSummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color chipColor;
  final Color chipBg;
  final String label;
  final List<String> items;

  const _AiSummaryRow({
    required this.icon,
    required this.iconColor,
    required this.chipColor,
    required this.chipBg,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((item) {
                  final isNone = item == '—' || item.toLowerCase().contains('none');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNone ? Colors.grey.shade100 : chipBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNone
                            ? Colors.grey.shade300
                            : chipColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isNone ? Colors.grey : chipColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
