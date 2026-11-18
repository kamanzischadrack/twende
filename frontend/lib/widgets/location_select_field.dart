// lib/widgets/location_select_field.dart
import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../models/location.dart';
import '../services/location_service.dart';

enum BcLocationFieldSize { small, normal }

class LocationSelectField extends StatefulWidget {
  final String label;
  final String? selectedLocationId;
  final String? initialText;
  final ValueChanged<Location?>? onSelectItem;
  final bool error;
  final String? helperText;
  final BcLocationFieldSize size;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const LocationSelectField({
    super.key,
    required this.label,
    this.selectedLocationId,
    this.initialText,
    this.onSelectItem,
    this.error = false,
    this.helperText,
    this.size = BcLocationFieldSize.normal,
    this.margin,
    this.backgroundColor,
  });

  @override
  State<LocationSelectField> createState() => _LocationSelectFieldState();
}

class _LocationSelectFieldState extends State<LocationSelectField> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.initialText ?? '';
    if (widget.selectedLocationId != null && widget.selectedLocationId!.isNotEmpty) {
      _loadInitialLocation();
    }
  }

  @override
  void didUpdateWidget(covariant LocationSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocationId != oldWidget.selectedLocationId) {
      if (widget.selectedLocationId == null || widget.selectedLocationId!.isEmpty) {
        setState(() {
          _displayName = '';
        });
      } else {
        _loadInitialLocation();
      }
    } else if (widget.initialText != null && widget.initialText != _displayName) {
      setState(() {
        _displayName = widget.initialText!;
      });
    }
  }

  Future<void> _loadInitialLocation() async {
    try {
      final loc = await LocationService.instance.getLocation(widget.selectedLocationId!);
      if (mounted) {
        setState(() {
          _displayName = loc.name ?? '';
        });
      }
    } catch (_) {}
  }

  void _openLocationSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _LocationSearchModal(
        title: widget.label,
        onSelected: (loc) {
          setState(() {
            _displayName = loc.name ?? '';
          });
          widget.onSelectItem?.call(loc);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = widget.size == BcLocationFieldSize.small;
    final height = isSmall ? 36.0 : 55.0;
    final fontSize = isSmall ? 12.5 : 16.0;
    final hasValue = _displayName.isNotEmpty;
    final bg = widget.backgroundColor ?? AppColors.screenBackground;

    final borderColor = widget.error
        ? AppColors.error
        : Colors.black.withValues(alpha: 0.23);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Box
              InkWell(
                onTap: _openLocationSearchDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 10 : 15,
                    vertical: isSmall ? 6 : 15,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.black,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasValue ? _displayName : widget.label,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: hasValue
                                ? Colors.black87
                                : Colors.black.withValues(alpha: 0.38),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasValue)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _displayName = '';
                            });
                            widget.onSelectItem?.call(null);
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Floating Label
              if (hasValue)
                Positioned(
                  top: -8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    color: bg,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.error
                            ? AppColors.error
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Helper / Error Text
          if (widget.helperText != null && widget.helperText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 4),
              child: Text(
                widget.helperText!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: widget.error
                      ? AppColors.error
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationSearchModal extends StatefulWidget {
  final String title;
  final ValueChanged<Location> onSelected;

  const _LocationSearchModal({
    required this.title,
    required this.onSelected,
  });

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  final _searchController = TextEditingController();
  List<Location> _locations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations(String keyword) async {
    setState(() {
      _loading = true;
    });

    try {
      List<Location> results;
      if (keyword.trim().isEmpty) {
        results = await LocationService.instance.getLocations();
      } else {
        results = await LocationService.instance.searchLocations(keyword.trim());
      }

      if (mounted) {
        setState(() {
          _locations = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locations = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _loadLocations,
              decoration: InputDecoration(
                hintText: AppStrings.t('SEARCH_PLACEHOLDER'),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          _loadLocations('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.screenBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 16),

          // Results List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _locations.isEmpty
                    ? Center(
                        child: Text(
                          'No locations found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _locations.length,
                        itemBuilder: (ctx, index) {
                          final loc = _locations[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.black,
                            ),
                            title: Text(
                              loc.name ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onTap: () => widget.onSelected(loc),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
