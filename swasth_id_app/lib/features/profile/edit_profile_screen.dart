import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final String title;
  final String mobile;
  final Map<String, dynamic> data;
  final String section; // 'Personal' or 'Medical'

  const EditProfileScreen({
    super.key,
    required this.title,
    required this.mobile,
    required this.data,
    required this.section,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.section == 'Personal') {
      _controllers['name'] = TextEditingController(text: widget.data['name'] ?? '');
      _controllers['age'] = TextEditingController(text: widget.data['age']?.toString() ?? '');
      _controllers['gender'] = TextEditingController(text: widget.data['gender'] ?? '');
      _controllers['address'] = TextEditingController(text: widget.data['address'] ?? '');
      _controllers['city'] = TextEditingController(text: widget.data['city'] ?? '');
      _controllers['state'] = TextEditingController(text: widget.data['state'] ?? '');
      _controllers['pincode'] = TextEditingController(text: widget.data['pincode'] ?? '');
    } else {
      _controllers['height_cm'] = TextEditingController(text: widget.data['height_cm']?.toString() ?? '');
      _controllers['weight_kg'] = TextEditingController(text: widget.data['weight_kg']?.toString() ?? '');
      _controllers['blood_group'] = TextEditingController(text: widget.data['blood_group'] ?? '');
      _controllers['vaccination_status'] = TextEditingController(text: widget.data['vaccination_status'] ?? '');
      _controllers['allergies'] = TextEditingController(text: widget.data['allergies'] ?? '');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> updateData = {'mobile': widget.mobile};
    _controllers.forEach((key, controller) {
      updateData[key] = controller.text.trim();
    });

    Map<String, dynamic> result;
    if (widget.section == 'Personal') {
      result = await ProfileService.updatePersonalDetails(updateData);
    } else {
      result = await ProfileService.updateMedicalDetails(updateData);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.section == 'Personal') ...[
                _buildTextField('Name', 'name'),
                _buildTextField('Age', 'age', isNumber: true),
                _buildTextField('Gender', 'gender'),
                _buildTextField('Address', 'address'),
                _buildTextField('City', 'city'),
                _buildTextField('State', 'state'),
                _buildTextField('Pincode', 'pincode', isNumber: true),
              ] else ...[
                _buildTextField('Height (cm)', 'height_cm', isNumber: true),
                _buildTextField('Weight (kg)', 'weight_kg', isNumber: true),
                _buildTextField('Blood Group', 'blood_group'),
                _buildTextField('Vaccination Status', 'vaccination_status'),
                _buildTextField('Allergies', 'allergies'),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
