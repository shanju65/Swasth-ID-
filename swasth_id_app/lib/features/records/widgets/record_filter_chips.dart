import 'package:flutter/material.dart';
import '../models/document_model.dart';
// Note: AppColors could be imported here if explicitly needed, but using Theme handles colors.

class RecordFilterChips extends StatelessWidget {
  final RecordType selectedFilter;
  final ValueChanged<RecordType> onFilterChanged;

  const RecordFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      RecordType.all,
      RecordType.prescription,
      RecordType.labReport,
      RecordType.xray,
      RecordType.scan,
      RecordType.notes,
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
