// lib/screens/auth/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasPassword = false;
  bool _loading = false;
  bool _initialized = false;

  bool _currentPasswordRequired = false;
  bool _currentPasswordError = false;
  bool _passwordRequired = false;
  bool _passwordLengthError = false;
  bool _confirmPasswordRequired = false;
  bool _confirmPasswordError = false;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id == null) {
      if (mounted) context.go('/sign-in');
      return;
    }

    final status = await UserService.instance.hasPassword(user.id!);
    if (mounted) {
      setState(() {
        _hasPassword = status == 200;
        _initialized = true;
      });
    }
  }

  void _clearErrors() {
    setState(() {
      _currentPasswordRequired = false;
      _currentPasswordError = false;
      _passwordRequired = false;
      _passwordLengthError = false;
      _confirmPasswordRequired = false;
      _confirmPasswordError = false;
    });
  }

  Future<bool> _validatePasswords() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id == null) return false;

    final current = _currentPasswordController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (_hasPassword) {
      if (current.isEmpty) {
        setState(() {
          _currentPasswordRequired = true;
          _currentPasswordError = false;
        });
        return false;
      }

      final checkStatus = await UserService.instance.checkPassword({
        '_id': user.id!,
        'password': current,
      });

      if (checkStatus != 200) {
        setState(() {
          _currentPasswordRequired = false;
          _currentPasswordError = true;
        });
        return false;
      }
    }

    if (password.isEmpty) {
      setState(() {
        _passwordRequired = true;
        _passwordLengthError = false;
      });
      return false;
    }

    if (password.length < 6) {
      setState(() {
        _passwordLengthError = true;
        _passwordRequired = false;
      });
      return false;
    }

    if (confirm.isEmpty) {
      setState(() {
        _confirmPasswordRequired = true;
        _confirmPasswordError = false;
      });
      return false;
    }

    if (password != confirm) {
      setState(() {
        _confirmPasswordError = true;
        _confirmPasswordRequired = false;
      });
      return false;
    }

    _clearErrors();
    return true;
  }

  Future<void> _handleUpdate() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final valid = await _validatePasswords();
      if (!valid) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final status = await UserService.instance.changePassword({
        '_id': user.id!,
        'password': _currentPasswordController.text,
        'newPassword': _passwordController.text,
        'strict': _hasPassword,
      });

      if (!mounted) return;

      if (status == 200) {
        _currentPasswordController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _hasPassword = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t('PASSWORD_UPDATE')),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t('PASSWORD_UPDATE_ERROR')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t('PASSWORD_UPDATE_ERROR')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppHeader(title: AppStrings.t('CHANGE_PASSWORD_TITLE')),
        drawer: const CustomDrawer(currentRoute: '/change-password'),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    String? currentPasswordHelperText;
    if (_currentPasswordRequired) {
      currentPasswordHelperText = AppStrings.t('REQUIRED');
    } else if (_currentPasswordError) {
      currentPasswordHelperText = AppStrings.t('PASSWORD_ERROR');
    }

    String? passwordHelperText;
    if (_passwordRequired) {
      passwordHelperText = AppStrings.t('REQUIRED');
    } else if (_passwordLengthError) {
      passwordHelperText = AppStrings.t('PASSWORD_LENGTH_ERROR');
    }

    String? confirmPasswordHelperText;
    if (_confirmPasswordRequired) {
      confirmPasswordHelperText = AppStrings.t('REQUIRED');
    } else if (_confirmPasswordError) {
      confirmPasswordHelperText = AppStrings.t('PASSWORDS_DONT_MATCH');
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('CHANGE_PASSWORD_TITLE')),
      drawer: const CustomDrawer(currentRoute: '/change-password'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasPassword)
                  BcTextInput(
                    label: AppStrings.t('CURRENT_PASSWORD'),
                    controller: _currentPasswordController,
                    secureTextEntry: true,
                    error: _currentPasswordRequired || _currentPasswordError,
                    helperText: currentPasswordHelperText,
                    onChangeText: (_) => setState(() {
                      _currentPasswordRequired = false;
                      _currentPasswordError = false;
                    }),
                  ),

                BcTextInput(
                  label: AppStrings.t('NEW_PASSWORD'),
                  controller: _passwordController,
                  secureTextEntry: true,
                  error: _passwordRequired || _passwordLengthError,
                  helperText: passwordHelperText,
                  onChangeText: (_) => setState(() {
                    _passwordRequired = false;
                    _passwordLengthError = false;
                  }),
                ),

                BcTextInput(
                  label: AppStrings.t('CONFIRM_PASSWORD'),
                  controller: _confirmPasswordController,
                  secureTextEntry: true,
                  error: _confirmPasswordRequired || _confirmPasswordError,
                  helperText: confirmPasswordHelperText,
                  onChangeText: (_) => setState(() {
                    _confirmPasswordRequired = false;
                    _confirmPasswordError = false;
                  }),
                ),

                const SizedBox(height: 10),

                BcButton(
                  label: AppStrings.t('UPDATE'),
                  isLoading: _loading,
                  onPress: _handleUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
