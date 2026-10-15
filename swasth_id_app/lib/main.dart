import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/core/theme/app_theme.dart';
import 'package:swasth_id_app/features/auth/login_screen.dart';
import 'package:swasth_id_app/navigation/bottom_nav.dart';
import 'package:swasth_id_app/features/doctor/doctor_home_screen.dart';
import 'package:swasth_id_app/features/worker/personal_details_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Swasth ID',
          theme: AppTheme.lightTheme,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.teal),
             scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          themeMode: currentMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final mobile = prefs.getString('mobile');
    final isRegistered = prefs.getBool('is_registered') ?? false;

    if (role != null && mobile != null) {
      print('AUTH DEBUG: Found session - Role: $role, Mobile: $mobile, IsRegistered: $isRegistered');
      if (role == 'Doctor') {
        _home = const DoctorHomeScreen();
      } else {
        // Health Worker
        if (isRegistered) {
          _home = const BottomNav();
        } else {
          _home = PersonalDetailsScreen(mobile: mobile);
        }
      }
    } else {
      print('AUTH DEBUG: No session found. Redirecting to Login.');
      _home = const LoginScreen();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _home!;
  }
}
