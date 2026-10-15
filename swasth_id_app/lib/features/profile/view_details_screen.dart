import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/features/profile/edit_profile_screen.dart';

class ViewDetailsScreen extends StatefulWidget {
  final String title;
  final String mobile;
  final Map<String, dynamic> data;
  final String section;

  const ViewDetailsScreen({
    super.key,
    required this.title,
    required this.mobile,
    required this.data,
    required this.section,
  });

  @override
  State<ViewDetailsScreen> createState() => _ViewDetailsScreenState();
}

class _ViewDetailsScreenState extends State<ViewDetailsScreen> {
  late Map<String, dynamic> _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = Map.from(widget.data);
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          title: "Edit ${widget.title}",
          mobile: widget.mobile,
          data: _currentData,
          section: widget.section,
        ),
      ),
    );

    if (result == true) {
      // In a real app we might re-fetch here, but for now let's hope the parent updates or we pass back data.
      // Actually, better to just pop with true if we want the parent (ProfileScreen) to refresh.
      // But we also want to update THIS screen. 
      // Let's assume ProfileScreen handles the master refresh. 
      // But we need to refresh THIS screen's data too if we don't pop.
      // Since EditProfileScreen returns `true` on success, we should ideally re-fetch or Signal parent.
      // For simplicity, let's pop this screen too with `true` so ProfileScreen refreshes everything.
      Navigator.pop(context, true);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryColor),
            onPressed: _navigateToEdit,
            tooltip: 'Edit Details',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GlassContainer(
           padding: const EdgeInsets.all(24),
           child: Column(
             children: widget.section == 'Personal' 
               ? [
                   _buildDetailRow("Name", _currentData['name']),
                   _buildDetailRow("Age", _currentData['age']?.toString()),
                   _buildDetailRow("Gender", _currentData['gender']),
                   _buildDetailRow("Mobile", widget.mobile), // Mobile is usually readonly/primary key-ish here
                   const Divider(height: 32),
                   _buildDetailRow("Address", _currentData['address']),
                   _buildDetailRow("City", _currentData['city']),
                   _buildDetailRow("State", _currentData['state']),
                   _buildDetailRow("Pincode", _currentData['pincode']),
                 ]
               : [
                   _buildDetailRow("Height", "${_currentData['height_cm']} cm"),
                   _buildDetailRow("Weight", "${_currentData['weight_kg']} kg"),
                   _buildDetailRow("BMI", "${_currentData['bmi']}"),
                   _buildDetailRow("Blood Group", _currentData['blood_group']),
                   const Divider(height: 32),
                   _buildDetailRow("Vaccination", _currentData['vaccination_status']),
                   _buildDetailRow("Allergies", _currentData['allergies']),
                 ],
           ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
