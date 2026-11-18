// lib/core/widgets/status_badge.dart
// Generic configurable status badge (same visual style as BookingStatusBadge).
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../shared/domain/enums.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    Color? backgroundColor,
    Color? textColor,
    Color? color,
    this.icon,
    this.fontSize = 11,
  })  : backgroundColor = backgroundColor ??
            (color != null ? const Color(0xFFF5F5F5) : const Color(0xFFF5F5F5)),
        textColor = textColor ?? (color ?? const Color(0xFF212121));

  /// Vehicle status badge factory.
  factory StatusBadge.vehicle(dynamic status) {
    final statusStr = status is VehicleStatus ? status.label : status.toString();
    Color bg, fg;
    IconData icon;
    switch (statusStr.toLowerCase()) {
      case 'available':
        bg = AppColors.syncSynced;
        fg = AppColors.vehicleAvailable;
        icon = Icons.check_circle_outline;
        break;
      case 'rented':
        bg = AppColors.syncQueued;
        fg = AppColors.vehicleRented;
        icon = Icons.key_outlined;
        break;
      case 'reserved':
        bg = const Color(0xFFEDE7F6);
        fg = AppColors.vehicleReserved;
        icon = Icons.event_available;
        break;
      case 'returned':
      case 'under inspection':
      case 'underinspection':
      case 'under_inspection':
        bg = const Color(0xFFF3E5F5);
        fg = Colors.deepPurple;
        icon = Icons.fact_check_outlined;
        break;
      case 'under maintenance':
      case 'undermaintenance':
      case 'under_maintenance':
        bg = const Color(0xFFFFF3E0);
        fg = AppColors.vehicleMaintenance;
        icon = Icons.build_outlined;
        break;
      case 'accident':
        bg = AppColors.syncConflict;
        fg = AppColors.vehicleAccident;
        icon = Icons.warning_amber_outlined;
        break;
      case 'out of service':
      case 'outofservice':
      case 'out_of_service':
        bg = const Color(0xFFF5F5F5);
        fg = AppColors.vehicleOos;
        icon = Icons.block_outlined;
        break;
      case 'sold':
      case 'archived':
        bg = const Color(0xFFE0E0E0);
        fg = Colors.black54;
        icon = Icons.archive_outlined;
        break;
      default:
        bg = AppColors.statusVoidBg;
        fg = AppColors.statusVoidText;
        icon = Icons.info_outline;
    }
    return StatusBadge(
      label: statusStr,
      backgroundColor: bg,
      textColor: fg,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: Colors.black),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
