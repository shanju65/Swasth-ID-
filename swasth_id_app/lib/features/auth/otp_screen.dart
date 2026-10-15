import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/features/auth/role_selection_screen.dart';
import 'package:swasth_id_app/features/board/board_screen.dart';
import 'package:swasth_id_app/features/auth/role_selection_screen.dart';
import 'package:swasth_id_app/features/board/board_screen.dart'; // Keep if used elsewhere or remove
import 'package:swasth_id_app/navigation/bottom_nav.dart';
import 'package:swasth_id_app/services/auth_service.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/primary_button.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.mobile,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final result = await AuthService.verifyOtp(otp, widget.verificationId, widget.mobile);

    setState(() => _isLoading = false);

    if (result['success']) {
      // Save mobile to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobile', widget.mobile);
      print('DEBUG: Saved mobile ${widget.mobile} to prefs');

      // SMART LOGIN: Check if user exists
      print('DEBUG: VerifyOTP Result - is_existing_user: ${result['is_existing_user']}');
      
         if (result['is_existing_user'] == true) {
            print('✅ DEBUG: Existing user detected. Redirecting to Board.');
            // Fix: Persist role and registration status for existing users
            await prefs.setString('role', 'Health Worker');
            await prefs.setBool('is_registered', true);

            if (result['health_id'] != null) {
               await prefs.setString('health_id', result['health_id']);
            }
            
            if (!mounted) return;
            // Navigate to Home (BottomNav)
            Navigator.pushAndRemoveUntil(
               context,
               MaterialPageRoute(builder: (context) => const BottomNav()),
               (route) => false,
            );
         } else {
         print('🆕 DEBUG: New user detected. Redirecting to Registration.');
         if (!mounted) return;
         // Navigate to Registration
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(
             builder: (context) => RoleSelectionScreen(mobile: widget.mobile),
           ),
         );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(
                Icons.lock_person_outlined,
                size: 50,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the OTP sent to',
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8)),
              ),
              Text(
                '+91 ${widget.mobile}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 48),

              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '• • • • • •',
                        hintStyle: const TextStyle(letterSpacing: 8, color: Colors.grey),
                        counterText: "",
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Verify OTP',
                      onPressed: _handleVerify,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resend OTP feature coming soon')),
                  );
                },
                child: const Text('Resend OTP', style: TextStyle(color: AppColors.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
