// lib/widgets/search_form.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import 'bc_button.dart';
import 'bc_date_picker.dart';
import 'bc_switch.dart';
import 'bc_time_picker.dart';
import 'location_select_field.dart';

class SearchForm extends StatefulWidget {
  final String? initialPickupLocationId;
  final String? initialDropOffLocationId;
  final String? pickupLocationText;
  final String? dropOffLocationText;
  final DateTime? initialFromDate;
  final TimeOfDay? initialFromTime;
  final DateTime? initialToDate;
  final TimeOfDay? initialToTime;
  final Color? backgroundColor;
  final bool isSmall;

  const SearchForm({
    super.key,
    this.initialPickupLocationId,
    this.initialDropOffLocationId,
    this.pickupLocationText,
    this.dropOffLocationText,
    this.initialFromDate,
    this.initialFromTime,
    this.initialToDate,
    this.initialToTime,
    this.backgroundColor,
    this.isSmall = false,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  String _pickupLocationId = '';
  String _dropOffLocationId = '';
  bool _sameLocation = true;

  DateTime? _fromDate;
  TimeOfDay? _fromTime;
  DateTime? _toDate;
  TimeOfDay? _toTime;

  bool _pickupError = false;
  bool _dropOffError = false;

  @override
  void initState() {
    super.initState();
    _pickupLocationId = widget.initialPickupLocationId ?? '';
    _dropOffLocationId = widget.initialDropOffLocationId ?? _pickupLocationId;
    _sameLocation = _pickupLocationId == _dropOffLocationId;

    final now = DateTime.now();
    _fromDate = widget.initialFromDate ?? now.add(const Duration(days: 3));
    _fromTime = widget.initialFromTime ?? const TimeOfDay(hour: 10, minute: 0);
    _toDate = widget.initialToDate ?? _fromDate!.add(const Duration(days: 3));
    _toTime = widget.initialToTime ?? const TimeOfDay(hour: 10, minute: 0);
  }

  void _handleSearch() {
    if (_pickupLocationId.isEmpty) {
      setState(() {
        _pickupError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('PICKUP_LOCATION_EMPTY')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_dropOffLocationId.isEmpty) {
      setState(() {
        _dropOffError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('DROP_OFF_LOCATION_EMPTY')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final fromDateTime = DateTime(
      _fromDate!.year,
      _fromDate!.month,
      _fromDate!.day,
      _fromTime!.hour,
      _fromTime!.minute,
    );

    final toDateTime = DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      _toTime!.hour,
      _toTime!.minute,
    );

    if (toDateTime.isBefore(fromDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drop-off date must be after pick-up date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final params = {
      'pickupLocation': _pickupLocationId,
      'dropOffLocation': _dropOffLocationId,
      'from': fromDateTime.millisecondsSinceEpoch.toString(),
      'to': toDateTime.millisecondsSinceEpoch.toString(),
      'd': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final uri = Uri(path: '/portal', queryParameters: params);
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = widget.isSmall;
    final pickerSize = isSmall ? BcPickerSize.small : BcPickerSize.normal;
    final locSize = isSmall ? BcLocationFieldSize.small : BcLocationFieldSize.normal;
    final btnSize = isSmall ? BcButtonSize.small : BcButtonSize.normal;
    final verticalMargin = isSmall
        ? const EdgeInsets.symmetric(vertical: 3)
        : const EdgeInsets.symmetric(vertical: 8);

    return Container(
      constraints: BoxConstraints(maxWidth: isSmall ? 380 : 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Pickup location
          LocationSelectField(
            label: AppStrings.t('PICKUP_LOCATION'),
            selectedLocationId: _pickupLocationId,
            initialText: widget.pickupLocationText,
            backgroundColor: widget.backgroundColor,
            size: locSize,
            margin: verticalMargin,
            error: _pickupError,
            helperText: _pickupError ? AppStrings.t('PICKUP_LOCATION_EMPTY') : null,
            onSelectItem: (loc) {
              setState(() {
                _pickupLocationId = loc?.id ?? '';
                _pickupError = false;
                if (_sameLocation) {
                  _dropOffLocationId = _pickupLocationId;
                }
              });
            },
          ),

          // 2. From Date & Time side-by-side
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BcDatePicker(
                  label: AppStrings.t('FROM_DATE'),
                  value: _fromDate,
                  size: pickerSize,
                  margin: verticalMargin,
                  backgroundColor: widget.backgroundColor,
                  minDate: DateTime.now(),
                  onChange: (date) {
                    if (date != null) {
                      setState(() {
                        _fromDate = date;
                        if (_toDate != null && _toDate!.isBefore(date)) {
                          _toDate = date.add(const Duration(days: 3));
                        }
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: BcTimePicker(
                  label: AppStrings.t('FROM_TIME'),
                  value: _fromTime,
                  size: pickerSize,
                  margin: verticalMargin,
                  backgroundColor: widget.backgroundColor,
                  onChange: (time) {
                    if (time != null) {
                      setState(() {
                        _fromTime = time;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          // 3. To Date & Time side-by-side
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BcDatePicker(
                  label: AppStrings.t('TO_DATE'),
                  value: _toDate,
                  size: pickerSize,
                  margin: verticalMargin,
                  backgroundColor: widget.backgroundColor,
                  minDate: _fromDate ?? DateTime.now(),
                  onChange: (date) {
                    if (date != null) {
                      setState(() {
                        _toDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: BcTimePicker(
                  label: AppStrings.t('TO_TIME'),
                  value: _toTime,
                  size: pickerSize,
                  margin: verticalMargin,
                  backgroundColor: widget.backgroundColor,
                  onChange: (time) {
                    if (time != null) {
                      setState(() {
                        _toTime = time;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          // 4. Drop-off location (if different location)
          if (!_sameLocation)
            LocationSelectField(
              label: AppStrings.t('DROP_OFF_LOCATION'),
              selectedLocationId: _dropOffLocationId,
              initialText: widget.dropOffLocationText,
              backgroundColor: widget.backgroundColor,
              size: locSize,
              margin: verticalMargin,
              error: _dropOffError,
              helperText: _dropOffError ? AppStrings.t('DROP_OFF_LOCATION_EMPTY') : null,
              onSelectItem: (loc) {
                setState(() {
                  _dropOffLocationId = loc?.id ?? '';
                  _dropOffError = false;
                });
              },
            ),

          SizedBox(height: isSmall ? 4 : 8),

          // 5. Search Button
          BcButton(
            label: AppStrings.t('SEARCH'),
            onPress: _handleSearch,
            size: btnSize,
            margin: isSmall
                ? const EdgeInsets.symmetric(vertical: 4)
                : const EdgeInsets.symmetric(vertical: 8),
          ),

          // 6. Same Location switch
          BcSwitch(
            label: AppStrings.t('SAME_LOCATION'),
            value: _sameLocation,
            onValueChange: (checked) {
              setState(() {
                _sameLocation = checked;
                if (checked) {
                  _dropOffLocationId = _pickupLocationId;
                } else {
                  _dropOffLocationId = '';
                }
              });
            },
            margin: isSmall
                ? const EdgeInsets.only(left: 4, top: 2, bottom: 2)
                : const EdgeInsets.only(left: 4, top: 4, bottom: 8),
          ),
        ],
      ),
    );
  }
}
