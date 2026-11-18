// lib/widgets/car_filter_panel.dart
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/car_filter.dart';
import 'bc_button.dart';

class CarFilterPanel extends StatefulWidget {
  final CarFilter initialFilter;
  final ValueChanged<CarFilter> onApply;
  final VoidCallback? onReset;

  const CarFilterPanel({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.onReset,
  });

  @override
  State<CarFilterPanel> createState() => _CarFilterPanelState();
}

class _CarFilterPanelState extends State<CarFilterPanel> {
  late List<String> _carTypes;
  late List<String> _gearboxes;
  late List<String> _fuelPolicies;
  late List<String> _mileages;
  double? _deposit;

  @override
  void initState() {
    super.initState();
    _carTypes = List.from(widget.initialFilter.carTypes ?? []);
    _gearboxes = List.from(widget.initialFilter.gearboxes ?? []);
    _fuelPolicies = List.from(widget.initialFilter.fuelPolicies ?? []);
    _mileages = List.from(widget.initialFilter.mileages ?? []);
    _deposit = widget.initialFilter.deposit;
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(
                opt.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              onSelected: (_) => onToggle(opt),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _handleApply() {
    final filter = CarFilter(
      carTypes: _carTypes.isEmpty ? null : _carTypes,
      gearboxes: _gearboxes.isEmpty ? null : _gearboxes,
      fuelPolicies: _fuelPolicies.isEmpty ? null : _fuelPolicies,
      mileages: _mileages.isEmpty ? null : _mileages,
      deposit: _deposit,
    );
    widget.onApply(filter);
  }

  void _handleReset() {
    setState(() {
      _carTypes = [];
      _gearboxes = [];
      _fuelPolicies = [];
      _mileages = [];
      _deposit = null;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Cars',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _handleReset,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(),

          // Car Type Filter
          _buildFilterSection(
            title: 'Car Type',
            options: [CarType.diesel, CarType.gasoline, CarType.electric, CarType.hybrid],
            selected: _carTypes,
            onToggle: (opt) {
              setState(() {
                if (_carTypes.contains(opt)) {
                  _carTypes.remove(opt);
                } else {
                  _carTypes.add(opt);
                }
              });
            },
          ),

          // Gearbox Filter
          _buildFilterSection(
            title: 'Gearbox',
            options: [GearboxType.manual, GearboxType.automatic],
            selected: _gearboxes,
            onToggle: (opt) {
              setState(() {
                if (_gearboxes.contains(opt)) {
                  _gearboxes.remove(opt);
                } else {
                  _gearboxes.add(opt);
                }
              });
            },
          ),

          // Fuel Policy
          _buildFilterSection(
            title: 'Fuel Policy',
            options: [FuelPolicy.likeForLike, FuelPolicy.freeTank],
            selected: _fuelPolicies,
            onToggle: (opt) {
              setState(() {
                if (_fuelPolicies.contains(opt)) {
                  _fuelPolicies.remove(opt);
                } else {
                  _fuelPolicies.add(opt);
                }
              });
            },
          ),

          // Mileage
          _buildFilterSection(
            title: 'Mileage',
            options: [Mileage.limited, Mileage.unlimited],
            selected: _mileages,
            onToggle: (opt) {
              setState(() {
                if (_mileages.contains(opt)) {
                  _mileages.remove(opt);
                } else {
                  _mileages.add(opt);
                }
              });
            },
          ),

          const SizedBox(height: 12),
          BcButton(
            label: 'Apply Filters',
            onPress: _handleApply,
          ),
        ],
      ),
    );
  }
}
