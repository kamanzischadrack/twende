// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_date_picker.dart';
import '../../widgets/bc_switch.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _birthDate;
  bool _enableEmailNotifications = false;
  bool _loading = true;
  bool _saving = false;

  // Validation errors
  bool _fullNameError = false;
  bool _phoneError = false;
  bool _birthDateError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    try {
      final user = await UserService.instance.getUser(authState.user!.id!);
      if (user != null && mounted) {
        setState(() {
          _fullNameController.text = user.fullName ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = user.phone ?? '';
          _locationController.text = user.location ?? '';
          _bioController.text = user.bio ?? '';
          _birthDate = user.birthDate;
          _enableEmailNotifications = user.enableEmailNotifications ?? false;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validatePhone(String phone) {
    if (phone.isEmpty) return false;
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone.trim());
  }

  bool _validateBirthDate(DateTime? date) {
    if (date == null) return false;
    final diff = DateTime.now().difference(date);
    return diff.inDays / 365 >= 21;
  }

  Future<void> _save() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate
    setState(() {
      _fullNameError = fullName.isEmpty;
      _phoneError = !_validatePhone(phone);
      _birthDateError = !_validateBirthDate(_birthDate);
    });

    if (_fullNameError || _phoneError || _birthDateError) return;

    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        '_id': authState.user!.id,
        'fullName': fullName,
        'phone': phone,
        'birthDate': _birthDate!.toIso8601String(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'enableEmailNotifications': _enableEmailNotifications,
      };
      final status = await UserService.instance.updateUser(data);
      if (mounted) {
        if (status == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t('SETTINGS_UPDATED')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t('GENERIC_ERROR')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t('GENERIC_ERROR')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDeleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('CONFIRM_TITLE')),
        content: Text(AppStrings.t('DELETE_AVATAR_CONFIRM')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.t('DELETE'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) return;
      try {
        final status =
            await UserService.instance.deleteAvatar(authState.user!.id!);
        if (status == 200 && mounted) {
          // Update local auth state - reload user
          await _loadUser();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t('UPDATED')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t('GENERIC_ERROR')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _handleAvatarUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.t('AVATAR_UPDATE_WEB')),
      ),
    );
  }

  Widget _buildAvatar(String? avatar) {
    final avatarUrl = avatar != null && avatar.isNotEmpty
        ? (avatar.startsWith('http')
            ? avatar
            : '${EnvConfig.cdnUsers}/$avatar')
        : null;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Avatar circle
        avatarUrl != null
            ? CircleAvatar(
                radius: 47,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: Colors.grey.shade200,
              )
            : CircleAvatar(
                radius: 47,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(
                  Icons.account_circle,
                  size: 94,
                  color: Colors.black,
                ),
              ),
        // Camera icon (bottom right)
        Positioned(
          bottom: 0,
          right: -4,
          child: GestureDetector(
            onTap: _handleAvatarUpload,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
            ),
          ),
        ),
        // Delete icon (bottom left) — only show if avatar exists
        if (avatarUrl != null)
          Positioned(
            bottom: 0,
            left: -4,
            child: GestureDetector(
              onTap: _confirmDeleteAvatar,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.broken_image_outlined,
                    size: 18, color: Colors.black),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.go('/sign-in?redirect=/settings');
          } catch (_) {}
        }
      });
      return Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppHeader(title: AppStrings.t('SETTINGS')),
        drawer: const CustomDrawer(currentRoute: '/settings'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.t('SIGN_IN'),
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              BcButton(
                label: AppStrings.t('SIGN_IN'),
                onPress: () {
                  try {
                    context.go('/sign-in?redirect=/settings');
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('SETTINGS')),
      drawer: const CustomDrawer(currentRoute: '/settings'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar section
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 24, top: 8),
                          child: _buildAvatar(user?.avatar),
                        ),
                      ),

                      // Full Name
                      BcTextInput(
                        label: AppStrings.t('FULL_NAME'),
                        controller: _fullNameController,
                        error: _fullNameError,
                        helperText: _fullNameError
                            ? AppStrings.t('REQUIRED')
                            : null,
                        onChangeText: (_) =>
                            setState(() => _fullNameError = false),
                      ),

                      // Email (read only)
                      BcTextInput(
                        label: AppStrings.t('EMAIL'),
                        controller: _emailController,
                        readOnly: true,
                        hideClearButton: true,
                      ),

                      // Phone
                      BcTextInput(
                        label: AppStrings.t('PHONE'),
                        controller: _phoneController,
                        error: _phoneError,
                        helperText: _phoneError
                            ? AppStrings.t('PHONE_NOT_VALID')
                            : null,
                        keyboardType: TextInputType.phone,
                        onChangeText: (_) =>
                            setState(() => _phoneError = false),
                      ),

                      // Birth Date
                      BcDatePicker(
                        label: AppStrings.t('BIRTH_DATE'),
                        value: _birthDate,
                        maxDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 21)),
                        error: _birthDateError,
                        helperText: _birthDateError
                            ? AppStrings.t('BIRTH_DATE_NOT_VALID')
                            : null,
                        onChange: (date) {
                          setState(() {
                            _birthDate = date;
                            _birthDateError = false;
                          });
                        },
                      ),

                      // Location (optional)
                      BcTextInput(
                        label: '${AppStrings.t('LOCATION')} (${AppStrings.t('OPTIONAL').toLowerCase()})',
                        controller: _locationController,
                      ),

                      // Bio (optional)
                      BcTextInput(
                        label: '${AppStrings.t('BIO')} (${AppStrings.t('OPTIONAL').toLowerCase()})',
                        controller: _bioController,
                      ),

                      const SizedBox(height: 8),

                      // Email notifications switch
                      BcSwitch(
                        value: _enableEmailNotifications,
                        label: AppStrings.t('ENABLE_EMAIL_NOTIFICATIONS'),
                        onValueChange: (v) =>
                            setState(() => _enableEmailNotifications = v),
                      ),

                      const SizedBox(height: 20),

                      // Save button
                      BcButton(
                        label: AppStrings.t('SAVE'),
                        isLoading: _saving,
                        onPress: _saving ? null : _save,
                        margin: const EdgeInsets.only(bottom: 12),
                      ),

                      // Change Password button
                      BcButton(
                        label: AppStrings.t('CHANGE_PASSWORD'),
                        isSecondary: true,
                        onPress: () => context.push('/change-password'),
                        margin: const EdgeInsets.only(bottom: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
