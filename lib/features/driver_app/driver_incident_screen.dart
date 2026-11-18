// lib/features/driver_app/driver_incident_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../shared/repositories/trip_repository.dart';

class DriverIncidentScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverIncidentScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverIncidentScreen> createState() => _DriverIncidentScreenState();
}

class _DriverIncidentScreenState extends ConsumerState<DriverIncidentScreen> {
  final _descController = TextEditingController();
  String _selectedType = 'Breakdown';
  String _severity = 'Medium';
  bool _isSubmitting = false;

  final List<String> _types = [
    'Breakdown',
    'Flat Tyre',
    'Accident / Collision',
    'Roadblock / Police Check',
    'Cargo Shift / Spill',
    'Fuel Leak',
    'Other Issue',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitIncident(TwendeTrip? trip) async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what happened in the incident description.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final incident = TripIncident(
      id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
      tripId: widget.tripId,
      vehiclePlate: trip?.vehiclePlate ?? 'RAF 789 T',
      driverName: trip?.driverName ?? 'Jean Habimana',
      type: _selectedType,
      severity: _severity,
      description: _descController.text.trim(),
      photoUrl: 'assets/images/mock_incident.jpg',
      timestamp: DateTime.now(),
      locationGps: '-1.9536, 30.0605 (RN1 Corridor)',
      status: 'Reported',
    );

    final repo = ref.read(tripRepositoryProvider);
    await repo.reportIncident(incident);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident report submitted. Fleet dispatch has been alerted.'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.error,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Report Incident / Issue',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<TwendeTrip?>(
        future: repo.getTripById(widget.tripId),
        builder: (context, snapshot) {
          final trip = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgent Hotline Call Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, color: Colors.black, size: 30),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Hotline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Immediate roadside rescue: +250 788 123 456',
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Connecting to Fleet Dispatcher...')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        child: const Text('Call Now', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Incident Type
                const Text(
                  'Issue Type *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      items: _types.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Severity level
                const Text(
                  'Severity Level *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Low', 'Medium', 'Critical'].map((level) {
                    final isSelected = _severity == level;
                    final color = level == 'Critical'
                        ? AppColors.error
                        : level == 'Medium'
                            ? AppColors.secondary
                            : AppColors.success;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _severity = level),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                level,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? color : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Description
                const Text(
                  'Description & Current Location Details *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g. Engine overheating 5km after Muhanga. Vehicle pulled over safely to the shoulder.',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 18),

                // Incident Photos
                const Text(
                  'Incident Photos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo Evidence Ready',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'GPS & timestamp tagged',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.black, size: 22),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : () => _submitIncident(trip),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Incident Report',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
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
