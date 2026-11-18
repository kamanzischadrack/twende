// lib/screens/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validator.dart';
import '../../services/user_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_date_picker.dart';
import '../../widgets/bc_error.dart';
import '../../widgets/bc_switch.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  bool _tosChecked = false;
  bool _loading = false;
  bool _success = false;

  bool _fullNameRequired = false;
  bool _emailRequired = false;
  bool _emailValid = true;
  bool _phoneRequired = false;
  bool _phoneValid = true;
  bool _birthDateRequired = false;
  bool _birthDateValid = true;
  bool _passwordRequired = false;
  bool _passwordLengthError = false;
  bool _confirmPasswordRequired = false;
  bool _confirmPasswordError = false;
  bool _tosError = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateFullName() {
    final valid = _fullNameController.text.trim().isNotEmpty;
    setState(() {
      _fullNameRequired = !valid;
    });
    return valid;
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailRequired = true;
        _emailValid = true;
      });
      return false;
    }
    final valid = Validator.isEmail(email);
    setState(() {
      _emailRequired = false;
      _emailValid = valid;
    });
    return valid;
  }

  bool _validatePhone() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneRequired = true;
        _phoneValid = true;
      });
      return false;
    }
    final valid = Validator.isPhone(phone);
    setState(() {
      _phoneRequired = false;
      _phoneValid = valid;
    });
    return valid;
  }

  bool _validateBirthDate() {
    if (_birthDate == null) {
      setState(() {
        _birthDateRequired = true;
        _birthDateValid = true;
      });
      return false;
    }

    final now = DateTime.now();
    var age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }

    final valid = age >= EnvConfig.minimumAge;
    setState(() {
      _birthDateRequired = false;
      _birthDateValid = valid;
    });
    return valid;
  }

  bool _validatePassword() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

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

    setState(() {
      _passwordRequired = false;
      _passwordLengthError = false;
      _confirmPasswordRequired = false;
      _confirmPasswordError = false;
    });
    return true;
  }

  Future<void> _handleSignUp() async {
    final fnOk = _validateFullName();
    if (!fnOk) return;

    final emOk = _validateEmail();
    if (!emOk) return;

    final phOk = _validatePhone();
    if (!phOk) return;

    final bdOk = _validateBirthDate();
    if (!bdOk) return;

    final pwOk = _validatePassword();
    if (!pwOk) return;

    if (!_tosChecked) {
      setState(() {
        _tosError = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _tosError = false;
    });

    try {
      final language = await UserService.instance.getLanguage();
      final data = {
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthDate': _birthDate!.toIso8601String(),
        'password': _passwordController.text,
        'language': language,
      };

      final status = await UserService.instance.signUp(data);

      if (!mounted) return;

      if (status == 200) {
        setState(() {
          _success = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t('GENERIC_ERROR')),
            backgroundColor: AppColors.error,
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
    if (_success) {
      return Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppHeader(title: AppStrings.t('SIGN_UP_TITLE')),
        drawer: const CustomDrawer(currentRoute: '/sign-up'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.t('SIGN_UP_SUCCESS_HEADING'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.t('SIGN_UP_SUCCESS_MESSAGE'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  BcButton(
                    label: AppStrings.t('SIGN_IN'),
                    onPress: () => context.go('/sign-in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    String? fullNameHelperText;
    if (_fullNameRequired) fullNameHelperText = AppStrings.t('REQUIRED');

    String? emailHelperText;
    if (_emailRequired) {
      emailHelperText = AppStrings.t('REQUIRED');
    } else if (!_emailValid) {
      emailHelperText = AppStrings.t('EMAIL_NOT_VALID');
    }

    String? phoneHelperText;
    if (_phoneRequired) {
      phoneHelperText = AppStrings.t('REQUIRED');
    } else if (!_phoneValid) {
      phoneHelperText = AppStrings.t('PHONE_NOT_VALID');
    }

    String? birthDateHelperText;
    if (_birthDateRequired) {
      birthDateHelperText = AppStrings.t('REQUIRED');
    } else if (!_birthDateValid) {
      birthDateHelperText = AppStrings.t('BIRTH_DATE_NOT_VALID');
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
      appBar: AppHeader(title: AppStrings.t('SIGN_UP_TITLE')),
      drawer: const CustomDrawer(currentRoute: '/sign-up'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full name
                BcTextInput(
                  label: AppStrings.t('FULL_NAME'),
                  controller: _fullNameController,
                  error: _fullNameRequired,
                  helperText: fullNameHelperText,
                  onChangeText: (_) => setState(() => _fullNameRequired = false),
                ),

                // Email
                BcTextInput(
                  label: AppStrings.t('EMAIL'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  error: _emailRequired || !_emailValid,
                  helperText: emailHelperText,
                  onChangeText: (_) => setState(() {
                    _emailRequired = false;
                    _emailValid = true;
                  }),
                ),

                // Phone
                BcTextInput(
                  label: AppStrings.t('PHONE'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  error: _phoneRequired || !_phoneValid,
                  helperText: phoneHelperText,
                  onChangeText: (_) => setState(() {
                    _phoneRequired = false;
                    _phoneValid = true;
                  }),
                ),

                // Birth Date
                BcDatePicker(
                  label: AppStrings.t('BIRTH_DATE'),
                  value: _birthDate,
                  error: _birthDateRequired || !_birthDateValid,
                  helperText: birthDateHelperText,
                  maxDate: DateTime.now(),
                  onChange: (val) {
                    setState(() {
                      _birthDate = val;
                      _birthDateRequired = false;
                      _birthDateValid = true;
                    });
                  },
                ),

                // Password
                BcTextInput(
                  label: AppStrings.t('PASSWORD'),
                  controller: _passwordController,
                  secureTextEntry: true,
                  error: _passwordRequired || _passwordLengthError,
                  helperText: passwordHelperText,
                  onChangeText: (_) => setState(() {
                    _passwordRequired = false;
                    _passwordLengthError = false;
                  }),
                ),

                // Confirm Password
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

                const SizedBox(height: 12),

                // Accept ToS Switch
                BcSwitch(
                  label: AppStrings.t('ACCEPT_TOS'),
                  value: _tosChecked,
                  onValueChange: (val) {
                    setState(() {
                      _tosChecked = val;
                      if (val) _tosError = false;
                    });
                  },
                  margin: const EdgeInsets.only(left: 4, bottom: 8),
                ),

                // ToS Error
                if (_tosError)
                  BcError(
                    message: AppStrings.t('TOS_ERROR'),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),

                // Sign Up Button
                BcButton(
                  label: AppStrings.t('SIGN_UP'),
                  isLoading: _loading,
                  onPress: _handleSignUp,
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
