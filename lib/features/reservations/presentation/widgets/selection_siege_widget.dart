import 'package:flutter/material.dart';

class SelectionSiegeWidget extends StatelessWidget {
  final String seatLabel;
  final bool isSelected;
  final bool isOccupied;
  final VoidCallback onTap;

  const SelectionSiegeWidget({
    super.key,
    required this.seatLabel,
    required this.isSelected,
    required this.isOccupied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey[800]!;
    if (isOccupied) color = Colors.redAccent.withValues(alpha: 0.5);
    if (isSelected) color = const Color(0xFF6C5CE7);

    return GestureDetector(
      onTap: isOccupied ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: Text(
            seatLabel,
            style: TextStyle(
              color: isOccupied ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
