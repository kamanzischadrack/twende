// lib/core/widgets/step_wizard.dart
// Multi-step wizard with orange progress bar + BcButton-style navigation.
// Used for handover, return, and trip inspection flows.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WizardStep {
  final String title;
  final String? subtitle;
  final Widget content;
  /// Return false to block "Next" (shows snackbar with [blockMessage]).
  final bool Function()? canProceed;
  final String blockMessage;

  const WizardStep({
    required this.title,
    this.subtitle,
    required this.content,
    this.canProceed,
    this.blockMessage = 'Please complete all required fields before continuing.',
  });
}

class StepWizard extends StatefulWidget {
  final List<WizardStep> steps;
  final VoidCallback? onComplete;
  final String completeLabel;
  final Future<void> Function()? onStepChange; // called after step advances

  const StepWizard({
    super.key,
    required this.steps,
    this.onComplete,
    this.completeLabel = 'COMPLETE',
    this.onStepChange,
  });

  @override
  State<StepWizard> createState() => _StepWizardState();
}

class _StepWizardState extends State<StepWizard> {
  int _current = 0;

  void _next() {
    final step = widget.steps[_current];
    if (step.canProceed != null && !step.canProceed!()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(step.blockMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_current < widget.steps.length - 1) {
      setState(() => _current++);
      widget.onStepChange?.call();
    } else {
      widget.onComplete?.call();
    }
  }

  void _back() {
    if (_current > 0) setState(() => _current--);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final isLast = _current == widget.steps.length - 1;
    final progress = (_current + 1) / widget.steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Orange progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppColors.cardBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Step ${_current + 1} of ${widget.steps.length}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (step.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(step.subtitle!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 16),
        step.content,
        const SizedBox(height: 20),
        // Navigation buttons — same sizing as BcButton (55px tall, r=10)
        Row(
          children: [
            if (_current > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('BACK'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(isLast ? widget.completeLabel : 'NEXT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
