// lib/core/widgets/approval_banner.dart
// Orange approval-required banner — matches existing orange design language.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ApprovalBanner extends StatelessWidget {
  final String reason;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ApprovalBanner({
    super.key,
    String? reason,
    String? message,
    int? count,
    this.actionLabel,
    VoidCallback? onAction,
    VoidCallback? onViewDetails,
  })  : reason = message ?? reason ?? 'Approval Required',
        onAction = onViewDetails ?? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.approvalPending,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.approvalPendingText.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.pending_actions,
              color: Colors.black, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approval Required',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.approvalPendingText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.approvalPendingText,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel ?? 'REVIEW',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
