import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeType { available, reserved, seatsLeft, soldOut, custom }

class CustomBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  const CustomBadge({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    this.textColor = AppColors.darkTextPrimary,
  });

  factory CustomBadge.available({String label = 'Available'}) {
    return CustomBadge(label: label, backgroundColor: AppColors.accentIndigo);
  }

  factory CustomBadge.reserved({String label = 'Reserved'}) {
    return CustomBadge(
      label: label,
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.success,
    );
  }

  factory CustomBadge.seatsLeft(int seats) {
    return const CustomBadge(
      label: 'Seats Left',
      backgroundColor: Color(0xFFF97316), // Couleur d'avertissement / orange
    );
  }

  factory CustomBadge.soldOut({String label = 'Sold Out'}) {
    return CustomBadge(label: label, backgroundColor: AppColors.error);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
