import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class _AiMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? suggestionAction;

  const _AiMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.suggestionAction,
  });
}

class AskFleetScreen extends StatefulWidget {
  const AskFleetScreen({super.key});

  @override
  State<AskFleetScreen> createState() => _AskFleetScreenState();
}

class _AskFleetScreenState extends State<AskFleetScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<_AiMessage> _messages = [
    _AiMessage(
      text: 'Hello! I am your Twende Fleet Intelligence Assistant. How can I help optimize vehicle utilization, maintenance schedules, or pricing today?',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final List<String> _quickPrompts = [
    'Check 4x4 SUV demand in Musanze',
    'Upcoming maintenance due in 7 days',
    'Reconciliation discrepancies this week',
    'Optimize weekend safari rate cards',
  ];

  void _sendQuery(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add(_AiMessage(
        text: query,
        isUser: true,
        time: DateTime.now(),
      ));
      _inputController.clear();
    });

    // Simulated deterministic AI advisory response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        if (query.contains('Musanze') || query.contains('demand')) {
          _messages.add(_AiMessage(
            text: 'Recommendation: Musanze Branch is currently experiencing 92% utilization on 4x4 SUVs due to gorilla trekking bookings. Consider rebalancing 2 Prado units from Kigali HQ to Musanze for the upcoming weekend.',
            isUser: false,
            time: DateTime.now(),
            suggestionAction: 'Initiate Inter-Branch Transfer',
          ));
        } else if (query.contains('maintenance')) {
          _messages.add(_AiMessage(
            text: 'Fleet Maintenance Alert: Suzuki Jimny (RAD 543 X) is at 33,100 km and overdue for oil service. Toyota HiAce (RAB 771 Z) will reach its 85,000 km inspection limit in approximately 4 days.',
            isUser: false,
            time: DateTime.now(),
            suggestionAction: 'View Work Orders',
          ));
        } else {
          _messages.add(_AiMessage(
            text: 'Analysis for "$query": Operations are stable. All vehicles have valid insurance and inspection certificates. Overall fleet readiness is currently 86%.',
            isUser: false,
            time: DateTime.now(),
          ));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('ASK_FLEET'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.askFleet),
      body: Column(
        children: [
          // Advisory Banner: AI is advisory-only
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFEEEE4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI recommendations are advisory (SRS §7.2). Final decisions require human verification.',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Message history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy, size: 18, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: msg.isUser ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: msg.isUser ? null : Border.all(color: AppColors.cardBorder),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              if (msg.suggestionAction != null) ...[
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Action "${msg.suggestionAction}" acknowledged.')),
                                    );
                                  },
                                  child: Text(msg.suggestionAction!, style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Quick prompts
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      backgroundColor: const Color(0xFFF5F5F5),
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      onPressed: () => _sendQuery(p),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Text input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask about fleet utilization, rates, maintenance...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                    onSubmitted: _sendQuery,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: () => _sendQuery(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
