import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/services/profile_service.dart';
import 'package:swasth_id_app/widgets/gradient_scaffold.dart';
import 'package:swasth_id_app/widgets/glass_container.dart';
import 'package:swasth_id_app/widgets/primary_button.dart';

class InsuranceVaultScreen extends StatefulWidget {
  final String mobile;
  final Map<String, dynamic> data;

  const InsuranceVaultScreen({super.key, required this.mobile, required this.data});

  @override
  State<InsuranceVaultScreen> createState() => _InsuranceVaultScreenState();
}

class _InsuranceVaultScreenState extends State<InsuranceVaultScreen> {
  bool _isEditing = false;
  late TextEditingController _providerController;
  late TextEditingController _policyController;
  late TextEditingController _validityController;
  late TextEditingController _tpaController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _providerController = TextEditingController(text: widget.data['provider'] ?? '');
    _policyController = TextEditingController(text: widget.data['policy_no'] ?? '');
    _validityController = TextEditingController(text: widget.data['valid_till'] ?? '');
    _tpaController = TextEditingController(text: widget.data['tpa'] ?? '');

    if (_providerController.text.isEmpty) {
      _isEditing = true;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final result = await ProfileService.updateInsuranceDetails({
      'mobile': widget.mobile,
      'provider': _providerController.text,
      'policy_no': _policyController.text,
      'valid_till': _validityController.text,
      'tpa': _tpaController.text
    });

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _isEditing = false;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insurance Details Saved")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text("Insurance Vault"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context, true),
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
        child: Column(
          children: [
            // Visual Card
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("HEALTH INSURANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       Icon(Icons.health_and_safety, color: Colors.white)
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _policyController.text.isNotEmpty ? _policyController.text : "XXXX-XXXX-XXXX",
                    style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Provider", style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text(_providerController.text.isNotEmpty ? _providerController.text : "N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Valid Till", style: TextStyle(color: Colors.white70, fontSize: 10)),
                          Text(_validityController.text.isNotEmpty ? _validityController.text : "MM/YY", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildField("Insurance Provider", _providerController, Icons.business),
                  const SizedBox(height: 16),
                  _buildField("Policy Number", _policyController, Icons.numbers),
                  const SizedBox(height: 16),
                  _buildField("Valid Until (DD/MM/YYYY)", _validityController, Icons.calendar_today),
                  const SizedBox(height: 16),
                  _buildField("TPA (Third Party Admin)", _tpaController, Icons.admin_panel_settings),
                  const SizedBox(height: 32),
                  
                  if (_isEditing)
                    PrimaryButton(
                      text: "Save Insurance Details",
                      onPressed: _save,
                      isLoading: _isLoading,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
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
