// lib/screens/tos/tos_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class TosScreen extends StatelessWidget {
  const TosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('TOS_MENU')),
      drawer: const CustomDrawer(currentRoute: '/tos'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Twende',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t('TOS_MENU'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Terms content card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        '1. Acceptance of Terms\n'
                        'By using the Twende application, you agree to be bound by these terms of service, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws.\n\n'
                        '2. Rental Agreement\n'
                        'Car bookings made through the Twende application are subject to the specific supplier\'s terms, driver verification, minimum age criteria (21+ years), and presentation of a valid driver\'s license at vehicle collection.\n\n'
                        '3. Cancellations & Amendments\n'
                        'Cancellations and amendments are governed by the policy selected at checkout. Included or purchased cancellation guarantees allow cancellation according to specified supplier terms.\n\n'
                        '4. Payment & Deposits\n'
                        'Security deposits may be authorized or collected depending on the vehicle and supplier policies. Full settlement or pay-later arrangements are clearly indicated during checkout.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
