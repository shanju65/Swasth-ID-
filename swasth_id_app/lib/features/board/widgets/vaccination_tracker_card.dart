import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:swasth_id_app/features/board/services/board_local_service.dart';

class VaccinationTrackerCard extends StatefulWidget {
  const VaccinationTrackerCard({super.key});

  @override
  State<VaccinationTrackerCard> createState() => _VaccinationTrackerCardState();
}

class _VaccinationTrackerCardState extends State<VaccinationTrackerCard> {
  final List<String> _allVaccines = [
    'BCG (Tuberculosis)',
    'Hepatitis B',
    'Polio (IPV)',
    'Tetanus (Tdap)',
    'COVID-19 (2 Doses)',
    'Influenza (Flu)',
  ];

  List<String> _takenVaccines = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final list = await BoardLocalService.getTakenVaccines();
    setState(() => _takenVaccines = list);
  }

  Future<void> _updateStatus(List<String> newTaken) async {
    await BoardLocalService.updateTakenVaccines(newTaken);
    _loadStatus();
  }

  void _showManager() {
    List<String> tempSelected = List.from(_takenVaccines);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Manage Vaccinations'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allVaccines.length,
                itemBuilder: (context, index) {
                  final vaccine = _allVaccines[index];
                  final isSelected = tempSelected.contains(vaccine);
                  return CheckboxListTile(
                    title: Text(vaccine),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                         if (val == true) {
                           tempSelected.add(vaccine);
                         } else {
                           tempSelected.remove(vaccine);
                         }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  _updateStatus(tempSelected);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int taken = _takenVaccines.length;
    final int total = _allVaccines.length;
    final double progress = total == 0 ? 0 : taken / total;
    
    // Determine next recommendation (first not taken)
    String nextDue = 'All Set!';
    for (var v in _allVaccines) {
      if (!_takenVaccines.contains(v)) {
        nextDue = 'Recommended: $v';
        break;
      }
    }

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vaccination Tracker',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textColor),
                ),
                GestureDetector(
                   onTap: _showManager,
                   child: Row(
                     children: [
                       Text(
                         '$taken/$total',
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                       ),
                       const SizedBox(width: 4),
                       const Icon(Icons.edit, size: 16, color: Colors.grey),
                     ],
                   ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.green.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 12),
             Row(
               children: [
                 const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                 const SizedBox(width: 4),
                 Expanded(
                   child: Text(
                    nextDue,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}
