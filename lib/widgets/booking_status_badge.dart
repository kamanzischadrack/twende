// lib/widgets/booking_status_badge.dart
import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';

class BookingStatusBadge extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry? margin;

  const BookingStatusBadge({
    super.key,
    required this.status,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'void':
        bgColor = AppColors.statusVoidBg;
        textColor = AppColors.statusVoidText;
        label = AppStrings.t('BOOKING_STATUS_VOID');
        break;
      case 'pending':
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPendingText;
        label = AppStrings.t('BOOKING_STATUS_PENDING');
        break;
      case 'deposit':
        bgColor = AppColors.statusDepositBg;
        textColor = AppColors.statusDepositText;
        label = AppStrings.t('BOOKING_STATUS_DEPOSIT');
        break;
      case 'paid':
        bgColor = AppColors.statusPaidBg;
        textColor = AppColors.statusPaidText;
        label = AppStrings.t('BOOKING_STATUS_PAID');
        break;
      case 'paidinfull':
      case 'paid_in_full':
        bgColor = AppColors.statusPaidInFullBg;
        textColor = AppColors.statusPaidInFullText;
        label = AppStrings.t('BOOKING_STATUS_PAID_IN_FULL');
        break;
      case 'reserved':
        bgColor = AppColors.statusReservedBg;
        textColor = AppColors.statusReservedText;
        label = AppStrings.t('BOOKING_STATUS_RESERVED');
        break;
      case 'cancelled':
        bgColor = AppColors.statusCancelledBg;
        textColor = AppColors.statusCancelledText;
        label = AppStrings.t('BOOKING_STATUS_CANCELLED');
        break;
      default:
        bgColor = Colors.grey.shade300;
        textColor = Colors.black54;
        label = status;
        break;
    }

    return Container(
      height: 28,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
