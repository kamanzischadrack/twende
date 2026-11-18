// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validator.dart';
import '../../services/user_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_link.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/social_login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _emailRequired = false;
  bool _emailValid = true;
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _handleReset() async {
    final valid = _validateEmail();
    if (!valid) return;

    setState(() {
      _loading = true;
    });

    try {
      final email = _emailController.text.trim();
      final status = await UserService.instance.resend(email, reset: true);

      if (!mounted) return;

      if (status == 200) {
        setState(() {
          _sent = true;
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
    String? emailHelperText;
    if (_emailRequired) {
      emailHelperText = AppStrings.t('REQUIRED');
    } else if (!_emailValid) {
      emailHelperText = AppStrings.t('EMAIL_NOT_VALID');
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('FORGOT_PASSWORD')),
      drawer: const CustomDrawer(currentRoute: '/forgot-password'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _sent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.t('RESET_EMAIL_SENT'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.6),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BcLink(
                        label: AppStrings.t('GO_TO_HOME'),
                        onPress: () => context.go('/'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.t('RESET_PASSWORD'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.6),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email input
                      BcTextInput(
                        label: AppStrings.t('EMAIL'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        error: _emailRequired || !_emailValid,
                        helperText: emailHelperText,
                        onSubmitEditing: _handleReset,
                        onChangeText: (_) => setState(() {
                          _emailRequired = false;
                          _emailValid = true;
                        }),
                      ),

                      // Social Login
                      const SocialLogin(),

                      // Reset Button
                      BcButton(
                        label: AppStrings.t('RESET'),
                        isLoading: _loading,
                        onPress: _handleReset,
                        margin: const EdgeInsets.only(top: 10),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
