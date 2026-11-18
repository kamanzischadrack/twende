// lib/features/portal/portal_pay_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';

enum _PortalPaymentType { mtnMomo, airtelMoney, card, bankTransfer }

class PortalPayScreen extends ConsumerStatefulWidget {
  final String token;

  const PortalPayScreen({super.key, required this.token});

  @override
  ConsumerState<PortalPayScreen> createState() => _PortalPayScreenState();
}

class _PortalPayScreenState extends ConsumerState<PortalPayScreen> {
  _PortalPaymentType _selectedMethod = _PortalPaymentType.mtnMomo;
  final TextEditingController _phoneController = TextEditingController(text: '0788123456');
  final TextEditingController _cardNumberController = TextEditingController(text: '4242 •••• •••• 4242');
  final TextEditingController _cardExpiryController = TextEditingController(text: '12/28');
  final TextEditingController _cardCvvController = TextEditingController(text: '883');

  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String _receiptReference = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractRepo = ref.watch(contractRepositoryProvider);
    final contractId = widget.token.startsWith('cnt_') ? widget.token : 'cnt_01';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E), // Twende Navy
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'twende.',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Secure Payment Gateway',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: FutureBuilder<TwendeContract?>(
        future: contractRepo.getContractById(contractId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final contract = snapshot.data;
          if (contract == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black),
                  const SizedBox(height: 12),
                  const Text('Payment invoice not found or expired.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Return Home'),
                  ),
                ],
              ),
            );
          }

          if (_paymentSuccess) {
            return _buildSuccessState(context, contract);
          }

          final amountToPay = contract.balanceDue > 0 ? contract.balanceDue : contract.depositAmount;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Summary Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contract.contractNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0E1B2E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${contract.vehicleName} (${contract.vehiclePlate})',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4EC),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Instant Settle',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      _buildCostRow('Base Vehicle Hire', MoneyUtils.format(contract.totalAmount - contract.depositAmount)),
                      const SizedBox(height: 6),
                      _buildCostRow('Security Caution Deposit (Refundable)', MoneyUtils.format(contract.depositAmount), isTeal: true),
                      const SizedBox(height: 6),
                      _buildCostRow('VAT (18% inclusive)', 'Included'),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount Due Now',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0E1B2E)),
                          ),
                          Text(
                            MoneyUtils.format(amountToPay),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method Selector
                const Text(
                  'Select Payment Channel',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0E1B2E)),
                ),
                const SizedBox(height: 10),

                _buildMethodTile(
                  method: _PortalPaymentType.mtnMomo,
                  title: 'MTN Mobile Money (MoMo)',
                  subtitle: 'Instant push prompt to your registered phone',
                  icon: Icons.phone_android,
                  accentColor: const Color(0xFFFFCC00),
                ),
                const SizedBox(height: 10),

                _buildMethodTile(
                  method: _PortalPaymentType.airtelMoney,
                  title: 'Airtel Money',
                  subtitle: 'Fast Airtel digital wallet debit',
                  icon: Icons.cell_tower,
                  accentColor: Colors.red,
                ),
                const SizedBox(height: 10),

                _buildMethodTile(
                  method: _PortalPaymentType.card,
                  title: 'Credit / Debit Card',
                  subtitle: 'Visa, Mastercard & international cards',
                  icon: Icons.credit_card,
                  accentColor: Colors.indigo,
                ),
                const SizedBox(height: 10),

                _buildMethodTile(
                  method: _PortalPaymentType.bankTransfer,
                  title: 'Bank Transfer (Equity / BK)',
                  subtitle: 'Manual receipt confirmation',
                  icon: Icons.account_balance,
                  accentColor: Colors.teal,
                ),
                const SizedBox(height: 20),

                // Method Specific Input Form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildSelectedMethodInputs(),
                ),
                const SizedBox(height: 24),

                // Pay Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);

                            // Simulate network processing with MoMo / Bank gateway
                            await Future.delayed(const Duration(milliseconds: 1200));

                            // Record payment in billing repo
                            final billingRepo = ref.read(billingRepositoryProvider);
                            final refCode = 'MOMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-RW';

                            final channel = _selectedMethod == _PortalPaymentType.mtnMomo
                                ? PaymentMethod.momoMtn
                                : (_selectedMethod == _PortalPaymentType.airtelMoney
                                    ? PaymentMethod.momoAirtel
                                    : PaymentMethod.card);

                            await billingRepo.recordPayment(
                              'inv_01',
                              amountToPay,
                              channel,
                              refCode,
                            );

                            setState(() {
                              _isProcessing = false;
                              _paymentSuccess = true;
                              _receiptReference = refCode;
                            });
                          },
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('SENDING MOMO PUSH PROMPT…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          )
                        : Text(
                            'PAY ${MoneyUtils.format(amountToPay)} NOW',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: Colors.black),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '256-bit SSL encrypted · PCI-DSS compliant checkout',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, {bool isTeal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isTeal ? Colors.teal : AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMethodTile({
    required _PortalPaymentType method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMethodInputs() {
    if (_selectedMethod == _PortalPaymentType.mtnMomo || _selectedMethod == _PortalPaymentType.airtelMoney) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedMethod == _PortalPaymentType.mtnMomo ? 'MTN MoMo Number (Rwanda)' : 'Airtel Money Number (Rwanda)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'e.g. 078 812 3456',
              prefixIcon: Icon(Icons.phone_android, color: Colors.black),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You will receive a prompt on your phone to enter your PIN and approve the transaction.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      );
    } else if (_selectedMethod == _PortalPaymentType.card) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              prefixIcon: Icon(Icons.credit_card, color: Colors.black),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardExpiryController,
                  decoration: const InputDecoration(labelText: 'MM / YY', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cardCvvController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'CVV / CVC', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank Transfer Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          SizedBox(height: 6),
          Text(
            'Bank: Bank of Kigali (BK)\nAccount Name: Twende Rwanda Fleet Ltd\nAccount No: 00040-06948201-90\nCurrency: RWF\nReference: Use Contract ID as transfer memo.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
          ),
        ],
      );
    }
  }

  Widget _buildSuccessState(BuildContext context, TwendeContract contract) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 48, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Confirmed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0E1B2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction $_receiptReference has been processed successfully. Your payment has been credited to Contract ${contract.contractNumber}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildCostRow('Receipt Reference', _receiptReference),
                  const SizedBox(height: 6),
                  _buildCostRow('Contract Ref', contract.contractNumber),
                  const SizedBox(height: 6),
                  _buildCostRow('Vehicle', '${contract.vehicleName} (${contract.vehiclePlate})'),
                  const SizedBox(height: 6),
                  _buildCostRow('Remaining Balance', 'RWF 0 (Settled)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('DOWNLOAD OFFICIAL RECEIPT (PDF)', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading digital VAT receipt PDF…')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E1B2E),
                  side: const BorderSide(color: Color(0xFF0E1B2E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('RETURN TO PORTAL HOME', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
