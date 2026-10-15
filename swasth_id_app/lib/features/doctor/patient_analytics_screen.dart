import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PatientAnalyticsScreen extends StatefulWidget {
  final List<dynamic> visits;
  final String patientName;

  const PatientAnalyticsScreen({
    super.key,
    required this.visits,
    required this.patientName,
  });

  @override
  State<PatientAnalyticsScreen> createState() => _PatientAnalyticsScreenState();
}

class _PatientAnalyticsScreenState extends State<PatientAnalyticsScreen>

    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ─── Computed analytics ──────────────────────────────────────────────────
  late final int _riskScore;
  late final String _riskLevel;
  late final Color _riskColor;
  late final List<String> _riskFactors;
  late final List<Map<String, dynamic>> _abnormalVitals;
  late final int _returnVisitCount;
  late final List<FlSpot> _tempSpots;
  late final List<FlSpot> _spo2Spots;
  late final List<FlSpot> _bpSpots;
  late final List<String> _visitDateLabels;
  late final Map<String, int> _visitTypeCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _computeAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _computeAnalytics() {
    final visits = widget.visits;
    int score = 0;
    final factors = <String>[];
    final abnormal = <Map<String, dynamic>>[];
    int returnVisits = 0;

    // Sort visits by date
    final sorted = [...visits]..sort((a, b) {
        try {
          return DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at']));
        } catch (_) {
          return 0;
        }
      });

    // ─── Vitals trend data ───────────────────────────────────────────────
    final tempSpots = <FlSpot>[];
    final spo2Spots = <FlSpot>[];
    final bpSpots = <FlSpot>[];
    final dateLabels = <String>[];

    for (int i = 0; i < sorted.length; i++) {
      final v = sorted[i];
      dateLabels.add(_shortDate(v['created_at']));

      final temp = _toDouble(v['temperature_c']);
      final spo2 = _toDouble(v['spo2']);
      final bp = _parseSystolic(v['bp']);

      if (temp != null) tempSpots.add(FlSpot(i.toDouble(), temp));
      if (spo2 != null) spo2Spots.add(FlSpot(i.toDouble(), spo2));
      if (bp != null) bpSpots.add(FlSpot(i.toDouble(), bp));

      // ─── Abnormal detection ──────────────────────────────────────────
      if (temp != null && temp > 38.5) {
        score++;
        abnormal.add({'date': dateLabels.last, 'issue': '🌡️ High Temp ${temp.toStringAsFixed(1)}°C', 'severity': 'High'});
        factors.add('Fever recorded (${temp.toStringAsFixed(1)}°C)');
      }
      if (spo2 != null && spo2 < 95) {
        score += 2;
        abnormal.add({'date': dateLabels.last, 'issue': '🫁 Low SpO2 ${spo2.toInt()}%', 'severity': 'Critical'});
        factors.add('Low SpO2 (${spo2.toInt()}%)');
      }
      if (bp != null && bp > 140) {
        score++;
        abnormal.add({'date': dateLabels.last, 'issue': '💓 High BP ${v['bp']}', 'severity': 'High'});
        factors.add('Hypertension (${v['bp']})');
      }
      if ((v['visit_type'] ?? '') == 'Emergency') {
        score++;
        factors.add('Emergency visit on ${dateLabels.last}');
      }
      if (v['referred'] == true) {
        score++;
        factors.add('Referred to ${v['referred_to'] ?? 'specialist'}');
      }
    }

    // ─── Return rate (visits within 7 days of each other) ─────────────
    for (int i = 1; i < sorted.length; i++) {
      try {
        final prev = DateTime.parse(sorted[i - 1]['created_at']);
        final curr = DateTime.parse(sorted[i]['created_at']);
        if (curr.difference(prev).inDays <= 7) returnVisits++;
      } catch (_) {}
    }
    if (returnVisits > 0) {
      score++;
      factors.add('$returnVisits quick return visit(s) within 7 days');
    }

    // ─── Visit type distribution ─────────────────────────────────────
    final typeCount = <String, int>{};
    for (final v in visits) {
      final t = v['visit_type'] ?? 'OPD';
      typeCount[t] = (typeCount[t] ?? 0) + 1;
    }

    // ─── Risk Level ──────────────────────────────────────────────────
    String level;
    Color color;
    if (score >= 4) {
      level = 'HIGH RISK';
      color = Colors.red.shade600;
    } else if (score >= 2) {
      level = 'MEDIUM RISK';
      color = Colors.orange.shade600;
    } else {
      level = 'LOW RISK';
      color = Colors.green.shade600;
    }

    _riskScore = score > 10 ? 10 : score;
    _riskLevel = level;
    _riskColor = color;
    _riskFactors = factors.toSet().toList(); // deduplicate
    _abnormalVitals = abnormal;
    _returnVisitCount = returnVisits;
    _tempSpots = tempSpots;
    _spo2Spots = spo2Spots;
    _bpSpots = bpSpots;
    _visitDateLabels = dateLabels;
    _visitTypeCount = typeCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.patientName,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Patient Analytics', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5C6BC0),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5C6BC0),
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Vitals'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
          ],
        ),
      ),
      body: widget.visits.isEmpty
          ? const Center(child: Text('No visit data available for analysis.', style: TextStyle(color: Colors.grey)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVitalsTab(),
                _buildOverviewTab(),
                _buildAlertsTab(),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1: Vitals Trend Chart
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVitalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_tempSpots.isNotEmpty) ...[
            _chartCard(
              title: '🌡️ Temperature Over Visits',
              subtitle: 'Normal: 36.1 – 37.2°C  |  Fever: > 38.5°C',
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
              title: '🫁 SpO2 (Oxygen) Over Visits',
              subtitle: 'Normal: ≥ 95%  |  Danger: < 90%',
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
              title: '💓 Blood Pressure (Systolic) Over Visits',
              subtitle: 'Normal: < 120 mmHg  |  Hypertension: > 140',
              chart: _lineChart(
                spots: _bpSpots,
                color: Colors.red.shade400,
                minY: 60,
                maxY: 200,
                dangerLine: 140,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_tempSpots.isEmpty && _spo2Spots.isEmpty && _bpSpots.isEmpty)
            _emptyCard('No vitals data recorded across visits yet.\nAsk the doctor to record temperature, BP and SpO2 during visits.'),
        ],
      ),
    );
  }

  Widget _chartCard({required String title, required String subtitle, required Widget chart}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              reservedSize: 36,
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
                    alignment: Alignment.topRight,
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

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2: Overview (Risk Score + Visit Distribution)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRiskScoreCard(),
          const SizedBox(height: 16),
          _buildReturnRateCard(),
          const SizedBox(height: 16),
          _buildVisitTypePieChart(),
          const SizedBox(height: 16),
          _buildVisitSummaryStats(),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_riskColor.withOpacity(0.85), _riskColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _riskColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Score Circle
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_riskScore', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const Text('/10', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.monitor_heart, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text('PATIENT RISK SCORE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 4),
                Text(_riskLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                if (_riskFactors.isEmpty)
                  const Text('No risk factors detected', style: TextStyle(color: Colors.white70, fontSize: 12))
                else
                  ..._riskFactors.take(3).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      const Icon(Icons.arrow_right, color: Colors.white70, size: 14),
                      Expanded(child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnRateCard() {
    final total = widget.visits.length;
    final pct = total > 1 ? (_returnVisitCount / (total - 1) * 100).toStringAsFixed(0) : '0';
    final isHigh = _returnVisitCount > 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: isHigh ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.repeat, color: isHigh ? Colors.red : Colors.green, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RETURN VISIT TRACKER', style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('$_returnVisitCount quick returns  ($pct%)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isHigh ? Colors.red : Colors.green)),
                Text(isHigh
                    ? 'Patient returned within 7 days — possible treatment failure'
                    : 'No quick returns — treatment appears effective',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTypePieChart() {
    if (_visitTypeCount.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF5C6BC0), Colors.orange, Colors.red, Colors.green, Colors.purple,
    ];
    final keys = _visitTypeCount.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📂 Visit Type Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 140, height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 30,
                    sections: List.generate(keys.length, (i) {
                      final key = keys[i];
                      final val = _visitTypeCount[key]!.toDouble();
                      return PieChartSectionData(
                        value: val,
                        color: colors[i % colors.length],
                        radius: 40,
                        showTitle: true,
                        title: '${val.toInt()}',
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(keys.length, (i) {
                    final key = keys[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text('$key (${_visitTypeCount[key]})', style: const TextStyle(fontSize: 13)),
                      ]),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitSummaryStats() {
    final total = widget.visits.length;
    final emergencies = widget.visits.where((v) => (v['visit_type'] ?? '') == 'Emergency').length;
    final referred = widget.visits.where((v) => v['referred'] == true).length;
    final vaccinated = widget.visits.where((v) => v['vaccine_given'] == true).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Record Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('$total', 'Total\nVisits', Colors.blue),
              _stat('$emergencies', 'Emergency', Colors.red),
              _stat('$referred', 'Referred', Colors.orange),
              _stat('$vaccinated', 'Vaccinated', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3: Alerts
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_abnormalVitals.isEmpty)
            _emptyCard('✅ No abnormal vitals detected across all visits.\nThis patient has a clean health record.')
          else ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(child: Text('${_abnormalVitals.length} abnormal vital reading(s) detected across visits.',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 14),
            ..._abnormalVitals.map((alert) => _alertCard(alert)),
          ],
          const SizedBox(height: 14),
          if (_returnVisitCount > 0)
            _alertCard({'date': 'Pattern', 'issue': '🔁 $_returnVisitCount return visit(s) within 7 days — possible treatment failure', 'severity': 'Medium'}),
        ],
      ),
    );
  }

  Widget _alertCard(Map alert) {
    final severity = alert['severity'] ?? 'Low';
    final isHigh = severity == 'High' || severity == 'Critical';
    final color = isHigh ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isHigh ? Icons.warning_amber : Icons.info_outline, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['issue'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                if (alert['date'] != 'Pattern')
                  Text('Recorded on ${alert['date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(severity, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6)),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
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
}
