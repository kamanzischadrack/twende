import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/domain/validation_rules.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  void _showRecordPaymentDialog(TwendeInvoice invoice) {
    PaymentMethod selectedMethod = PaymentMethod.momoMtn;
    final amountController = TextEditingController(text: invoice.balanceDue.toStringAsFixed(0));
    final refController = TextEditingController(text: 'MOMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final amt = double.tryParse(amountController.text) ?? 0.0;
          final valResult = ValidationRules.checkPaymentAmount(
            amount: amt,
            balanceDue: invoice.balanceDue,
          );

          return AlertDialog(
            title: Text('Record Payment - ${invoice.invoiceNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${invoice.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Outstanding Balance: ${MoneyUtils.format(invoice.balanceDue, invoice.currency)}',
                    style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  const Text('Payment Channel:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PaymentMethod>(
                    initialValue: selectedMethod,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: PaymentMethod.values.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (${invoice.currency}) *',
                      border: const OutlineInputBorder(),
                      errorText: valResult.isValid ? null : valResult.errorMessage,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Reference / Receipt # *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: !valResult.isValid
                    ? null
                    : () async {
                        final billingRepo = ref.read(billingRepositoryProvider);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        await billingRepo.recordPayment(
                          invoice.id,
                          amt,
                          selectedMethod,
                          refController.text.trim(),
                        );
                        nav.pop();
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(content: Text('Payment of ${MoneyUtils.format(amt, invoice.currency)} recorded successfully!')),
                        );
                      },
                child: const Text('Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingRepo = ref.watch(billingRepositoryProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('INVOICES'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.billing),
      body: Column(
        children: [
          // Aging Buckets Summary Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildAgingTile('Current (0-30d)', '195,000 RWF', Colors.teal)),
                const SizedBox(width: 8),
                Expanded(child: _buildAgingTile('31-60d', '400,000 RWF', Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildAgingTile('60d+ Overdue', '0 RWF', AppColors.error)),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: FutureBuilder<PaginatedResult<TwendeInvoice>>(
              future: billingRepo.getInvoices(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final invoices = snapshot.data?.items ?? [];
                if (invoices.isEmpty) {
                  return const Center(child: Text('No invoices recorded.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final inv = invoices[idx];
                    final isPaid = inv.balanceDue <= 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              StatusBadge(
                                label: isPaid ? 'PAID IN FULL' : 'PENDING PAYMENT',
                                color: isPaid ? Colors.green : AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer: ${inv.customerName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Issued: ${dateFormat.format(inv.issueDate)} • Due: ${dateFormat.format(inv.dueDate)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Invoiced', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(MoneyUtils.format(inv.totalAmount, inv.currency), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Amount Paid', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(MoneyUtils.format(inv.paidAmount, inv.currency), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(
                                    MoneyUtils.format(inv.balanceDue, inv.currency),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: inv.balanceDue > 0 ? AppColors.error : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isPaid) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Record Settlement (MoMo / Card / Bank)'),
                                onPressed: () => _showRecordPaymentDialog(inv),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingTile(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
