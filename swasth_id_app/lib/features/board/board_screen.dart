import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/auth/login_screen.dart';
import 'package:swasth_id_app/features/board/widgets/activity_card.dart';
import 'package:swasth_id_app/features/board/widgets/body_health_card.dart';
import 'package:swasth_id_app/features/board/widgets/health_status_card.dart';
import 'package:swasth_id_app/features/board/widgets/quick_actions_grid.dart';
import 'package:swasth_id_app/features/board/widgets/recent_visits_card.dart';
import 'package:swasth_id_app/features/board/widgets/medication_reminder_card.dart';
import 'package:swasth_id_app/features/board/widgets/appointment_card.dart';
import 'package:swasth_id_app/features/board/widgets/vaccination_tracker_card.dart';
import 'package:swasth_id_app/services/api_service.dart';
import 'package:swasth_id_app/features/records/services/visit_service.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/animate_in.dart';

class BoardScreen extends StatefulWidget {
  final Function(int)? onTabChange; // Callback to switch bottom nav tabs
  final bool isVisible;

  const BoardScreen({super.key, this.onTabChange, this.isVisible = false});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isLoading = true;
  bool _showTip = false; // Ephemeral tip state
  String? _healthId;
  String _mobile = ''; // Store mobile for display
  Map<String, dynamic>? _profileData;
  List<dynamic> _visits = [];
  String _district = 'Unknown';
  int _age = 25; // Default
  String _alertLevel = 'LOW';

  @override
  void initState() {
    super.initState();
    _fetchBoardData();
    _triggerTip();
  }

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _triggerTip();
    }
  }

  void _triggerTip() {
    // Reset first to ensure animation replays if called rapidly
    setState(() => _showTip = false);
    
    // Show tip after small delay, hide after 5 seconds
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.isVisible) {
         setState(() => _showTip = true);
         
         Future.delayed(const Duration(seconds: 4), () {
           if (mounted) setState(() => _showTip = false);
         });
      } else if (mounted) {
         // Fallback if visibility check not strictly enforced or first load
         setState(() => _showTip = true);
         Future.delayed(const Duration(seconds: 4), () {
           if (mounted) setState(() => _showTip = false);
         });
      }
    });
  }

  // Helper helper to safe parse numbers
  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _fetchBoardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Get Mobile
      String mobile = prefs.getString('mobile') ?? '';
      if (mounted) setState(() => _mobile = mobile); // Update UI
      
      print('DEBUG: Fetching Board Data for Mobile: $mobile');

      if (mobile.isEmpty) {
         print('DEBUG: No mobile found in prefs. Using fallback.');
         mobile = '9444529010'; // Fallback
         if (mounted) setState(() => _mobile = '$mobile (Fallback)');
      }
      
      // 2. Get Health ID
      print('DEBUG: Calling confirmIdVerification...');
      final idResult = await ApiService.confirmIdVerification(
        mobile: mobile,
        idType: 'Aadhaar', 
        idNumber: '000000000000', 
      );
      print('DEBUG: confirmIdVerification result: $idResult');

      if (idResult['success'] == true || idResult.containsKey('health_id')) {
        _healthId = idResult['health_id'] ?? idResult['data']?['health_id'];
        print('DEBUG: Got Health ID: $_healthId');
        
        if (_healthId != null) {
          // 3. Fetch Profile
          print('DEBUG: Fetching Profile...');
          final profileResult = await ApiService.getPatientProfile(_healthId!);
          print('DEBUG: Profile Result: $profileResult');

          if (profileResult['success'] == true) {
            final data = profileResult['data'];
            if (mounted) {
              setState(() {
                _profileData = data['medical_details'];
                Map<String, dynamic> personal = data['personal_details'] ?? {};
                _district = personal['city'] ?? 'Trivandrum';
                _age = personal['age'] ?? 25; 
                _alertLevel = 'LOW'; 
              });
            }
          } else {
             print('DEBUG: Failed to fetch profile: ${profileResult['message']}');
          }

          // 4. Fetch Visits
          try {
            final visits = await VisitService.getVisits(_healthId!);
            if (mounted) {
              setState(() {
                _visits = visits;
              });
            }
          } catch (e) {
            print('Error fetching visits: $e');
          }
        }
      } else {
        print('DEBUG: Failed to get Health ID');
      }
    } catch (e) {
      print('Error loading board: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRecords() {
    // If we have a callback to switch tabs, use it (Records is usually index 1)
    if (widget.onTabChange != null) {
      widget.onTabChange!(1); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switched to Records Tab')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. Main Content
                RefreshIndicator(
                  onRefresh: _fetchBoardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        AnimateIn(
                          delay: const Duration(milliseconds: 100),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    'My Health Board',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4)
                                    )
                                  ]
                                ),
                                child: const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryColor,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 1. Body Health (BMI + Ideal Weight)
                        AnimateIn(
                          delay: const Duration(milliseconds: 200),
                          child: BodyHealthCard(
                            heightCm: _safeParseDouble(_profileData?['height_cm']),
                            weightKg: _safeParseDouble(_profileData?['weight_kg']),
                            age: _age, 
                            bmi: _safeParseDouble(_profileData?['bmi']),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 2. Health Status (District Alert)
                        AnimateIn(
                          delay: const Duration(milliseconds: 250),
                          child: HealthStatusCard(
                            district: _district,
                            alertLevel: _alertLevel,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Medication Reminder
                        const AnimateIn(
                          delay: Duration(milliseconds: 300),
                          child: MedicationReminderCard(),
                        ),
                        const SizedBox(height: 20),
                        
                        // 4. Appointment
                        const AnimateIn(
                          delay: Duration(milliseconds: 350),
                          child: AppointmentCard(),
                        ),
                        const SizedBox(height: 20),
                        
                        // 5. Vaccination Tracker
                         const AnimateIn(
                          delay: Duration(milliseconds: 400),
                          child: VaccinationTrackerCard(),
                        ),
                        const SizedBox(height: 20),

                        // 6. Activity (Real Pedometer)
                        const AnimateIn(
                          delay: Duration(milliseconds: 450),
                          child: ActivityCard(),
                        ),
                        const SizedBox(height: 20),

                        // 7. Recent Visits
                        AnimateIn(
                          delay: const Duration(milliseconds: 500),
                          child: RecentVisitsCard(
                            visits: _visits,
                            onViewAll: _navigateToRecords,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 8. Quick Actions
                        AnimateIn(
                          delay: const Duration(milliseconds: 600),
                          child: QuickActionsGrid(
                            onRecordsTap: _navigateToRecords,
                            onAiTap: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening Swasth AI...')),
                              );
                            },
                            onUploadTap: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Upload Document feature coming soon')),
                              );
                            },
                            onPhcTap: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Finding nearby PHC...')),
                              );
                            },
                          ),
                        ),
                        
                        // Padding
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // 2. Ephemeral Health Tip Overlay
                if (_showTip)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: -100, end: 50),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Positioned(
                        top: value,
                        left: 20,
                        right: 20,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Tip: Drink water 30 mins before meals!",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showTip = false),
                                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
