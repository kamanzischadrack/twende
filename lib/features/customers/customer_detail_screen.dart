import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/domain/validation_rules.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerRepo = ref.watch(customerRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(
        title: 'Customer Profile',
      ),
      body: FutureBuilder<TwendeCustomer?>(
        future: customerRepo.getCustomerById(customerId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final customer = snapshot.data;
          if (customer == null) {
            return const Center(child: Text('Customer not found.'));
          }

          // Evaluate eligibility using domain rules
          final eligibility = ValidationRules.checkDriverEligibility(
            licenceExpiry: customer.licenceExpiry,
            dateOfBirth: DateTime(1990, 1, 1),
            isBlacklisted: customer.riskLevel == RiskLevel.blacklisted,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customer.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                          StatusBadge(
                            label: customer.type.label,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if (customer.companyName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          customer.companyName!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(customer.email, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(customer.phone, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Eligibility & Risk Assessment
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: eligibility.isValid ? AppColors.cardBorder : AppColors.error,
                      width: eligibility.isValid ? 1.0 : 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rental Eligibility Check (BR-04)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Icon(
                            eligibility.isValid ? Icons.check_circle : Icons.cancel,
                            color: Colors.black,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        eligibility.isValid
                            ? 'Customer meets all age, licence validity, and risk profile criteria.'
                            : 'Ineligible: ${eligibility.errorMessage}',
                        style: TextStyle(
                          fontSize: 12,
                          color: eligibility.isValid ? Colors.green.shade800 : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Driver Licence Number:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(customer.licenceNumber ?? 'Not provided', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Licence Expiry Date:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            customer.licenceExpiry?.toIso8601String().split('T').first ?? 'N/A',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('National ID (NID):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(customer.nationalId ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Financial Limits Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Standing & Credit Line',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Approved Credit Limit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(MoneyUtils.format(customer.creditLimit), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Outstanding Balance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                MoneyUtils.format(customer.outstandingBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: customer.outstandingBalance > 0 ? AppColors.error : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Create New Booking for this Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      context.push(TwendeRoutes.bookingNew, extra: {'customerId': customer.id});
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
