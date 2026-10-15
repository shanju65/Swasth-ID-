import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/symptom_survey/data/survey_data.dart';
import 'package:swasth_id_app/features/symptom_survey/screens/analysis_screen.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/features/symptom_survey/widgets/body_map_widget.dart';

class SurveyScreen extends StatefulWidget {
  final String languageCode;

  const SurveyScreen({super.key, required this.languageCode});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final PageController _pageController = PageController();
  
  int _currentStep = 0;
  bool _isSpeaking = false;
  Map<String, dynamic> _responses = {};
  
  @override
  void initState() {
    super.initState();
    _initTts();
    _playQuestionVoice(0);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(_getTtsLanguage(widget.languageCode));
    await _flutterTts.setSpeechRate(0.4); // Slower, calmer
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setCancelHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  String _getTtsLanguage(String code) {
    switch (code) {
      case 'hi': return 'hi-IN';
      case 'ta': return 'ta-IN';
      default: return 'en-IN';
    }
  }

  Future<void> _playQuestionVoice(int index) async {
    if (index >= SurveyData.questions.length) return;
    
    final question = SurveyData.questions[index];
    final text = question.voiceText[widget.languageCode] ?? question.questionText[widget.languageCode] ?? '';
    
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _onOptionSelected(String option) {
    final question = SurveyData.questions[_currentStep];
    
    if (question.allowMultiSelect) {
      final List<String> current = List<String>.from(_responses['step_${question.id}'] ?? []);
      if (current.contains(option)) {
        current.remove(option);
      } else {
        current.add(option);
      }
      setState(() {
        _responses['step_${question.id}'] = current;
      });
    } else {
      setState(() {
        _responses['step_${question.id}'] = option;
      });
      // Auto advance for single select
      Future.delayed(const Duration(milliseconds: 500), _nextStep);
    }
  }

  void _nextStep() {
    if (_currentStep < SurveyData.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
      _playQuestionVoice(_currentStep);
    } else {
      _finishSurvey();
    }
  }

  void _finishSurvey() {
    _flutterTts.stop();
    
    // Compile Final Data
    // Aggregate symptoms from steps 4, 5, 6, 7
    final List<String> allSymptoms = [];
    if (_responses['step_4'] != null) allSymptoms.addAll(List<String>.from(_responses['step_4']));
    if (_responses['step_5'] != null) allSymptoms.addAll(List<String>.from(_responses['step_5']));
    if (_responses['step_6'] != null) allSymptoms.addAll(List<String>.from(_responses['step_6']));
    if (_responses['step_7'] != null) allSymptoms.addAll(List<String>.from(_responses['step_7']));
    
    // Remove 'None' entries from symptoms
    allSymptoms.removeWhere((s) => s == 'None');

    final compiledData = {
      'language': widget.languageCode,
      'age_group': _responses['step_1'],
      'gender': _responses['step_2'],
      'pain_areas': _responses['step_3'],
      'symptoms': allSymptoms,
      'duration': _responses['step_8'], // Shifted ID
      'severity': _responses['step_9'], // Shifted ID
      'warning_signs': _responses['step_10'], // Shifted ID
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AnalysisScreen(data: compiledData)),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Progress Calculation
    final double progress = (_currentStep + 1) / SurveyData.questions.length;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryColor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentStep + 1}/${SurveyData.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Question Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                itemCount: SurveyData.questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(SurveyData.questions[index]);
                },
              ),
            ),

            // Bottom Control (For Multi-Select or Replay)
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion question) {
    final translatedQuestion = question.questionText[widget.languageCode] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Voice Animation placeholder
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: _isSpeaking ? AppColors.primaryColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: _isSpeaking ? 20 : 0,
                  spreadRadius: _isSpeaking ? 5 : 0,
                )
              ]
            ),
            child: IconButton(
              icon: Icon(
                _isSpeaking ? Icons.graphic_eq : Icons.volume_up,
                color: _isSpeaking ? Colors.white : AppColors.primaryColor,
              ),
              onPressed: () => _playQuestionVoice(_currentStep),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            translatedQuestion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),

          if (question.id == 3) ...[
            SizedBox(
              height: 400,
              child: BodyMapWidget(
                selectedParts: List<String>.from(_responses['step_${question.id}'] ?? []),
                onPartSelected: _onOptionSelected,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: question.options.where((opt) => 
                  !['Head', 'Neck', 'Shoulders', 'Chest', 'Stomach', 'Arms', 'Legs', 'Knees', 'Feet'].contains(opt)
                ).map((opt) {
                  return _buildOptionButton(question, opt);
                }).toList(),
              ),
            ),
          ] else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: question.options.map((opt) {
              return _buildOptionButton(question, opt);
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOptionButton(SurveyQuestion question, String optionKey) {
    final translatedLabel = SurveyData.getTranslation(optionKey, widget.languageCode);
    bool isSelected = false;

    if (question.allowMultiSelect) {
      final List<String> current = List<String>.from(_responses['step_${question.id}'] ?? []);
      isSelected = current.contains(optionKey);
    } else {
      isSelected = _responses['step_${question.id}'] == optionKey;
    }

    return InkWell(
      onTap: () => _onOptionSelected(optionKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Text(
          translatedLabel,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final question = SurveyData.questions[_currentStep];
    
    if (!question.allowMultiSelect) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            widget.languageCode == 'en' ? 'Next' : (widget.languageCode == 'hi' ? 'आगे बढ़ें' : 'அடுத்து'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
