import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/services/swasth_ai_service.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:translator/translator.dart';
import 'dart:convert';
import 'package:swasth_id_app/features/symptom_survey/screens/doctor_recommendation_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const AnalysisScreen({super.key, required this.data});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _analyzeSymptoms();
  }

  Future<void> _analyzeSymptoms() async {
    try {
      // 1. Construct Broad Prompt
      final prompt = """
      Act as a medical AI assistant. Analyze these symptoms considering Viral, Bacterial, Fungal, and other causes:
      Age Group: ${widget.data['age_group']}
      Gender: ${widget.data['gender']}
      Pain Area: ${widget.data['pain_areas']}
      Symptoms: ${widget.data['symptoms']}
      Duration: ${widget.data['duration']}
      Severity: ${widget.data['severity']}
      Warning Signs: ${widget.data['warning_signs']}

      Return ONLY a raw JSON object (no markdown, no backticks) with these exact keys:
      {
        "possible_causes": ["Cause 1", "Cause 2", "Cause 3"],
        "home_care": ["Tip 1", "Tip 2"],
        "warning_signs": ["Sign 1"],
        "consult_doctor": "Yes/No (Reason)"
      }
      Use cautious language. Do not diagnose. Ensure the JSON is valid.
      """;

      final response = await SwasthAiService.askAi(prompt, healthId: 'guest_survey');
      String aiText = response['answer'] ?? '{}';
      
      // Clean up potential markdown formatting from AI
      aiText = aiText.replaceAll('```json', '').replaceAll('```', '').trim();

      // 2. Parse JSON
      Map<String, dynamic> parsedData;
      try {
        parsedData = jsonDecode(aiText);
      } catch (e) {
        parsedData = {
            "possible_causes": ["Analysis inconclusive"],
            "home_care": ["Please consult a doctor directly."],
            "warning_signs": [],
            "consult_doctor": "Yes"
        };
      }

      // 3. Translate Content
      final translator = GoogleTranslator();
      final targetLang = widget.data['language'] == 'hi' ? 'hi' : (widget.data['language'] == 'ta' ? 'ta' : 'en');
      
      if (targetLang != 'en') {
        parsedData['possible_causes'] = await _translateList(parsedData['possible_causes'], translator, targetLang);
        parsedData['home_care'] = await _translateList(parsedData['home_care'], translator, targetLang);
        parsedData['warning_signs'] = await _translateList(parsedData['warning_signs'], translator, targetLang);
        parsedData['consult_doctor'] = (await translator.translate(parsedData['consult_doctor'], to: targetLang)).text;
      }

      if (mounted) {
        setState(() {
          _result = parsedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = null; // Show error state
        });
      }
    }
  }

  Future<List<dynamic>> _translateList(List<dynamic> list, GoogleTranslator translator, String lang) async {
    List<dynamic> translated = [];
    for (var item in list) {
       final trans = await translator.translate(item.toString(), to: lang);
       translated.add(trans.text);
    }
    return translated;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: _isLoading 
            ? _buildLoading()
            : (_result == null ? _buildError() : _buildResult()),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                ]
              ),
              child: const Icon(Icons.hub, size: 50, color: AppColors.primaryColor),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Analyzing wide range of causes...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "(Viral, Bacterial, Fungal & more)",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          const Text("Analysis Failed", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
             onPressed: () {
               setState(() => _isLoading = true);
               _analyzeSymptoms();
             },
             child: const Text("Try Again")
          )
        ],
      ),
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Header
          Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              const Spacer(),
              const Text("Health Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              const Opacity(opacity: 0, child: Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Possible Causes
          _buildSectionTitle("Possible Causes", Icons.search),
          ...(_result!['possible_causes'] as List).map((cause) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.coronavirus, color: Colors.blue, size: 20),
              ),
              title: Text(cause.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          )),
          const SizedBox(height: 20),

          // Home Care
          _buildSectionTitle("Home Care & Relief", Icons.health_and_safety),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: (_result!['home_care'] as List).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tip.toString(), style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Warning Signs
          if ((_result!['warning_signs'] as List).isNotEmpty) ...[
             _buildSectionTitle("Watch Out For", Icons.warning_amber),
             ...(_result!['warning_signs'] as List).map((sign) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(sign.toString(), style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold))),
                ]),
             )),
             const SizedBox(height: 20),
          ],

          // Consult Doctor
           _buildSectionTitle("Doctor Consultation", Icons.local_hospital),
           Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 30),
                  const SizedBox(width: 16),
                  Expanded(child: Text(
                      _result!['consult_doctor'].toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  )),
                ],
              ),
           ),

          const SizedBox(height: 30),

          // Connect to Care (NEW)
          _buildConnectToCare(),

          const SizedBox(height: 30),
          const Center(child: Text(
             "Disclaimer: Not a medical diagnosis.",
             style: TextStyle(color: Colors.grey, fontSize: 12),
          )),
        ],
      ),
    );
  }

  Widget _buildConnectToCare() {
    final specialty = _determineSpecialty();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                 child: const Icon(Icons.person_search, color: Colors.white),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Recommended Step", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                     const SizedBox(height: 4),
                     Text("Consult a $specialty", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   ],
                 ),
               )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DoctorRecommendationScreen(specialty: specialty)
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              child: Text("Find $specialty Near You", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  String _determineSpecialty() {
    final symptoms = (widget.data['symptoms'] as List).map((e) => e.toString().toLowerCase()).toList();
    final causes = (_result?['possible_causes'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
    final allText = [...symptoms, ...causes].join(' ');

    // Check Age first
    final ageGroup = widget.data['age_group'].toString();

    // 1. CRITICAL / SPECIALIZED (Check these FIRST)
    if (allText.contains('heart') || allText.contains('chest pain') || allText.contains('cardiac')) return 'Cardiologist';
    if (allText.contains('bone') || allText.contains('joint') || allText.contains('knee') || allText.contains('back') || allText.contains('fracture')) return 'Orthopedist';
    if (allText.contains('eye') || allText.contains('vision')) return 'Ophthalmologist';
    if (ageGroup == '0–12') return 'Pediatrician';

    // 2. MODERATE / COMMON
    if (allText.contains('skin') || allText.contains('rash') || allText.contains('itch') || allText.contains('boil') || allText.contains('dermat')) return 'Dermatologist';
    if (allText.contains('stomach') || allText.contains('vomit') || allText.contains('diarrhea') || allText.contains('digest') || allText.contains('acid') || allText.contains('gas')) return 'Gastroenterologist';
    
    // 3. ENT / RESPIRATORY (Common overlap, check last)
    if (allText.contains('throat') || allText.contains('ear') || allText.contains('nose') || allText.contains('cold') || allText.contains('cough') || allText.contains('flu')) return 'ENT Specialist';

    // Default
    return 'General Physician';
  }

  Widget _buildSectionTitle(String title, IconData icon) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12.0),
       child: Row(
         children: [
           Icon(icon, size: 20, color: AppColors.textColor),
           const SizedBox(width: 8),
           Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
         ],
       ),
     );
  }
}
