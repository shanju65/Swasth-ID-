import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/auth/login_screen.dart';
import 'package:swasth_id_app/features/profile/edit_profile_screen.dart';
import 'package:swasth_id_app/features/profile/terms_conditions_screen.dart';
import 'package:swasth_id_app/features/profile/view_details_screen.dart';
import 'package:swasth_id_app/features/profile/emergency_contacts_screen.dart';
import 'package:swasth_id_app/features/profile/insurance_vault_screen.dart';
import 'package:swasth_id_app/main.dart'; // For themeNotifier
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _mobile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _mobile = prefs.getString('mobile');

    if (_mobile != null) {
      final result = await ProfileService.fetchProfile(_mobile!);
      if (result['success']) {
        if (mounted) {
          setState(() {
            _profileData = result['data'];
            _isLoading = false;
            
            // Persist emergency contact for SOS feature
            final emergency = _profileData?['emergency_contacts'];
            if (emergency != null && emergency['phone'] != null) {
              prefs.setString('emergency_phone', emergency['phone'].toString());
            }
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToView(String section, Map<String, dynamic> data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewDetailsScreen(
          title: section == 'Personal' ? 'Personal Details' : 'Medical Details',
          mobile: _mobile!,
          data: data,
          section: section,
        ),
      ),
    );

    if (result == true) {
      _loadProfile(); // Refresh data
    }
  }

  void _navigateToEmergency(Map<String, dynamic> data) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen(mobile: _mobile!, data: data)));
    if (result == true) _loadProfile();
  }

  void _navigateToInsurance(Map<String, dynamic> data) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => InsuranceVaultScreen(mobile: _mobile!, data: data)));
    if (result == true) _loadProfile();
  }

  void _showHealthCard() {
    if (_profileData == null || _profileData?['health_id'] == null) {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Health ID not generated yet")),
          );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Health ID Card", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: _profileData!['health_id'],
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _profileData!['health_id'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.primaryColor),
              ),
              const SizedBox(height: 20),
               TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('English'), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text('Hindi'), onTap: () => Navigator.pop(context)),
            ListTile(title: const Text('Malayalam'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GradientScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final personal = _profileData?['personal_details'] ?? {};
    final medical = _profileData?['medical_details'] ?? {};
    final emergency = _profileData?['emergency_contacts'] ?? {};
    final insurance = _profileData?['insurance_details'] ?? {};
    final healthId = _profileData?['health_id'] ?? 'N/A';
    final name = personal['name'] ?? 'Swasth User';

    return GradientScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
        child: Column(
          children: [
            // Profile Header
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryColor,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                Text(
                  '+91 ${_mobile ?? ""}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                if (healthId != 'N/A')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      healthId,
                      style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Settings Sections
            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSectionHeader("Account"),
                  _buildListTile(Icons.person_outline, "Personal Details", onTap: () => _navigateToView('Personal', personal)),
                  _buildListTile(Icons.medical_services_outlined, "Medical Details", onTap: () => _navigateToView('Medical', medical)),
                  _buildListTile(Icons.contact_phone_outlined, "Emergency Contacts", onTap: () => _navigateToEmergency(emergency)),
                  _buildListTile(Icons.security_outlined, "Insurance Vault", onTap: () => _navigateToInsurance(insurance)),
                  _buildListTile(Icons.badge_outlined, "Health ID Card", onTap: _showHealthCard),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  
                  _buildSectionHeader("App Settings"),
                   ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, _) {
                      return SwitchListTile(
                        secondary: Icon(
                          mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, 
                          color: AppColors.primaryColor
                        ),
                        title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w500)),
                        value: mode == ThemeMode.dark,
                        activeColor: AppColors.primaryColor,
                        onChanged: _toggleTheme,
                      );
                    },
                  ),
                  _buildListTile(Icons.language, "Language", onTap: _showLanguageDialog),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  
                  _buildSectionHeader("Support"),
                  _buildListTile(Icons.help_outline, "Help & Center", onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Help Center coming soon!")));
                  }),
                   _buildListTile(Icons.description_outlined, "Terms & Conditions", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                  }),
                  _buildListTile(Icons.logout, "Logout", onTap: () => _logout(context), isDestructive: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Version 1.0.0",
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
