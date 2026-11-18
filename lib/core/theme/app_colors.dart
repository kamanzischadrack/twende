// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFF37022);       // Twende orange
  static const Color primaryDark = Color(0xFFD4601A);
  static const Color primaryLight = Color(0xFFF5944F);
  static const Color secondary = Color(0xFFF5A623);      // Amber accent from SRS 1.4

  // Notification badge / accent blue (matches the RN badge: #1976d2)
  static const Color accent = Color(0xFF1976D2);
  static const Color badgeBlue = Color(0xFF1976D2);

  // ─── Layout ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);    // screen background
  static const Color screenBackground = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFD9D8D9);    // car card border

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF70757A);  // matches RN #70757a
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;

  // ─── Misc ────────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEBEBEB);        // matches RN footer border
  static const Color footer = Color(0xFFF2F2F2);         // footer background

  // ─── Button secondary ────────────────────────────────────────────────────
  static const Color buttonSecondary = Color(0xFF999999); // grey secondary button
  static const Color greyButton = Color(0xFF999999);

  // ─── Booking Status — BACKGROUND colors (pastel) ─────────────────────────
  // Matches BookingStatus.tsx exactly
  static const Color statusVoidBg       = Color(0xFFD9D9D9);
  static const Color statusPendingBg    = Color(0xFFFBDCC2);
  static const Color statusDepositBg    = Color(0xFFCDECDA);
  static const Color statusPaidBg       = Color(0xFFD1F9D1);
  static const Color statusPaidInFullBg = Color(0xFF77BC23);
  static const Color statusReservedBg   = Color(0xFFD9E7F4);
  static const Color statusCancelledBg  = Color(0xFFFBDFDE);

  // ─── Booking Status — TEXT colors ────────────────────────────────────────
  static const Color statusVoidText       = Color(0xFF6E7C86);
  static const Color statusPendingText    = Color(0xFFEF6C00);
  static const Color statusDepositText    = Color(0xFF3CB371);
  static const Color statusPaidText       = Color(0xFF77BC23);
  static const Color statusPaidInFullText = Colors.white;
  static const Color statusReservedText   = Color(0xFF1E88E5);
  static const Color statusCancelledText  = Color(0xFFE53935);

  // ─── Extra icons (car card) ───────────────────────────────────────────────
  static const Color extraIncluded  = Color(0xFF1F9201);  // green check
  static const Color extraExcluded  = Color(0xFFF44336);  // red clear
  static const Color extraPaid      = Color(0x59000000);  // grey info (rgba 35% opacity)

  // ─── Twende: Vehicle Status Colors ───────────────────────────────────────
  static const Color vehicleAvailable   = Color(0xFF388E3C); // success green
  static const Color vehicleRented      = Color(0xFF1976D2); // accent blue
  static const Color vehicleMaintenance = Color(0xFFF57C00); // warning orange
  static const Color vehicleAccident    = Color(0xFFD32F2F); // error red
  static const Color vehicleOos         = Color(0xFF757575); // grey
  static const Color vehicleReserved    = Color(0xFF7B1FA2); // purple
  static const Color vehicleInspection  = Color(0xFF0288D1); // cyan-blue

  // ─── Twende: Approval / Sync States ──────────────────────────────────────
  static const Color approvalPending     = Color(0xFFFFF3E0); // amber light bg
  static const Color approvalPendingText = Color(0xFFE65100); // deep orange text
  static const Color syncQueued          = Color(0xFFE3F2FD); // blue light
  static const Color syncConflict        = Color(0xFFFFEBEE); // red light
  static const Color syncSynced          = Color(0xFFE8F5E9); // green light

  // ─── Twende: AI / Advisory ───────────────────────────────────────────────
  static const Color aiSuggestionBg   = Color(0xFFF3E5F5); // purple light
  static const Color aiSuggestionText = Color(0xFF6A1B9A); // deep purple

  // ─── Twende: Finance ─────────────────────────────────────────────────────
  static const Color balanceDue  = Color(0xFFD32F2F); // red — customer owes
  static const Color refundDue   = Color(0xFF388E3C); // green — refund to customer
  static const Color neutralGrey = Color(0xFF90A4AE); // aging / secondary numbers
}
