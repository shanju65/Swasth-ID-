import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/board/services/board_local_service.dart';

class MedicationReminderCard extends StatefulWidget {
  const MedicationReminderCard({super.key});

  @override
  State<MedicationReminderCard> createState() => _MedicationReminderCardState();
}

class _MedicationReminderCardState extends State<MedicationReminderCard> {
  List<Map<String, dynamic>> _meds = [];

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    final meds = await BoardLocalService.getMedications();
    setState(() => _meds = meds);
  }

  Future<void> _addMedication(String name, String time) async {
    final newMed = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'time': time,
      'status': 'pending', 
    };
    await BoardLocalService.addMedication(newMed);
    _loadMeds();
  }

  Future<void> _toggleStatus(String id) async {
    await BoardLocalService.toggleMedicationStatus(id);
    _loadMeds();
  }

  Future<void> _deleteMed(String id) async {
    await BoardLocalService.deleteMedication(id);
    _loadMeds();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Medication', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.medication),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context, 
                  initialTime: TimeOfDay.now()
                );
                if (time != null) {
                  // ignore: use_build_context_synchronously
                  setState(() => selectedTime = time);
                  // Force rebuild of dialog part not possible easily without statefulbuilder, but closing is fine
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime != null ? selectedTime!.format(context) : 'Select Time',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && selectedTime != null) {
                    _addMedication(nameController.text, selectedTime!.format(context));
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('Add to Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final takenCount = _meds.where((m) => m['status'] == 'taken').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_rounded, color: Colors.purple, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Medications Today',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textColor),
                ),
                const Spacer(),
                if (_meds.isNotEmpty)
                  Text(
                    '$takenCount/${_meds.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.purple, size: 20),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            if (_meds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No medications added yet.\nTap + to start tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _meds.map((med) => _buildMedChip(med)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedChip(Map<String, dynamic> med) {
    bool isTaken = med['status'] == 'taken';
    return GestureDetector(
      onTap: () => _toggleStatus(med['id']),
      onLongPress: () => _deleteMed(med['id']),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isTaken ? Colors.purple.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTaken ? Colors.purple : Colors.transparent,
            width: 1.5
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isTaken ? Colors.purple : AppColors.textColor,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  med['time'],
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(
              isTaken ? Icons.check_circle : Icons.circle_outlined,
              color: isTaken ? Colors.purple : Colors.grey,
              size: 20,
            )
          ],
        ),
      ),
    );
  }
}
