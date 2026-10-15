import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/widgets/primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String mobile;
  final Map<String, dynamic> data;

  const EmergencyContactsScreen({super.key, required this.mobile, required this.data});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _relationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name'] ?? '');
    _phoneController = TextEditingController(text: widget.data['phone'] ?? '');
    _relationController = TextEditingController(text: widget.data['relation'] ?? '');
    
    // Auto-edit mode if no data exists
    if (_nameController.text.isEmpty) {
      _isEditing = true;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    final result = await ProfileService.updateEmergencyContacts({
      'mobile': widget.mobile,
      'name': _nameController.text,
      'phone': _phoneController.text,
      'relation': _relationController.text
    });

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _isEditing = false;
        // Update local persist
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('emergency_phone', _phoneController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency Contacts Saved")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context, true), // Return true to refresh
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryColor),
              onPressed: () => setState(() => _isEditing = true),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildField("Contact Name", _nameController, Icons.person),
              const SizedBox(height: 16),
              _buildField("Phone Number", _phoneController, Icons.phone, isNumber: true),
              const SizedBox(height: 16),
              _buildField("Relation", _relationController, Icons.people),
              const SizedBox(height: 32),
              
              if (_isEditing)
                PrimaryButton(
                  text: "Save Contact",
                  onPressed: _save,
                  isLoading: _isLoading,
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryColor),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
