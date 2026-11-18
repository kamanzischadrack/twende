// lib/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/permissions.dart';
import '../../core/auth/route_guard.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validator.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_error.dart';
import '../../widgets/bc_link.dart';
import '../../widgets/bc_switch.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _stayConnected = false;
  bool _emailRequired = false;
  bool _emailValid = true;
  bool _passwordRequired = false;
  bool _passwordLengthError = false;
  bool _passwordError = false;
  bool _blacklisted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailRequired = false;
      _emailValid = true;
      _passwordRequired = false;
      _passwordLengthError = false;
      _passwordError = false;
      _blacklisted = false;
    });
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
    final isValid = Validator.isEmail(email);
    setState(() {
      _emailRequired = false;
      _emailValid = isValid;
    });
    return isValid;
  }

  bool _validatePassword() {
    final password = _passwordController.text;
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
    setState(() {
      _passwordRequired = false;
      _passwordLengthError = false;
    });
    return true;
  }

  Future<void> _handleSignIn() async {
    _clearErrors();
    final emailOk = _validateEmail();
    if (!emailOk) return;

    final passwordOk = _validatePassword();
    if (!passwordOk) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    await _completeSignIn(email, password);
  }

  Future<void> _completeSignIn(String email, String password) async {
    setState(() => _isLoading = true);
    final success =
        await ref.read(authProvider.notifier).signIn(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      final user = ref.read(currentUserProvider);
      if (user?.blacklisted == true) {
        await ref.read(authProvider.notifier).signOut();
        setState(() {
          _blacklisted = true;
        });
      } else {
        final role = appRoleFromName(user?.role);
        final String destination;
        if (role == AppRole.driverChauffeur) {
          destination = '/driver';
        } else if (role == AppRole.customer) {
          destination = '/portal';
        } else if (AppRouteGuard.canAccess(user, '/dashboard')) {
          destination = '/dashboard';
        } else if (AppRouteGuard.canAccess(user, '/bookings')) {
          destination = '/bookings';
        } else {
          destination = '/dashboard';
        }
        context.go(destination);
      }
    } else {
      setState(() {
        _passwordError = true;
      });
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

    String? passwordHelperText;
    if (_passwordRequired) {
      passwordHelperText = AppStrings.t('REQUIRED');
    } else if (_passwordLengthError) {
      passwordHelperText = AppStrings.t('PASSWORD_LENGTH_ERROR');
    } else if (_passwordError) {
      passwordHelperText = AppStrings.t('SIGN_IN_ERROR');
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('SIGN_IN_TITLE'),
        hideTitle: false,
      ),
      drawer: const CustomDrawer(currentRoute: '/sign-in'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Email field
                BcTextInput(
                  label: AppStrings.t('EMAIL'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  error: _emailRequired || !_emailValid,
                  helperText: emailHelperText,
                  onChangeText: (_) => _clearErrors(),
                ),

                // Password field
                BcTextInput(
                  label: AppStrings.t('PASSWORD'),
                  controller: _passwordController,
                  secureTextEntry: true,
                  error: _passwordRequired ||
                      _passwordLengthError ||
                      _passwordError,
                  helperText: passwordHelperText,
                  onChangeText: (_) => _clearErrors(),
                  onSubmitEditing: _handleSignIn,
                ),

                const SizedBox(height: 16),

                // Stay connected switch
                BcSwitch(
                  label: AppStrings.t('STAY_CONNECTED'),
                  value: _stayConnected,
                  onValueChange: (val) {
                    setState(() {
                      _stayConnected = val;
                    });
                  },
                  margin: const EdgeInsets.only(left: 4, bottom: 12),
                ),

                // Sign In Button
                BcButton(
                  label: AppStrings.t('SIGN_IN'),
                  isLoading: _isLoading,
                  onPress: _handleSignIn,
                  margin: const EdgeInsets.only(bottom: 12),
                ),

                // Sign Up Button (Secondary grey)
                BcButton(
                  label: AppStrings.t('SIGN_UP'),
                  isSecondary: true,
                  onPress: () => context.push('/sign-up'),
                  margin: const EdgeInsets.only(bottom: 12),
                ),

                // Forgot Password link
                Center(
                  child: BcLink(
                    label: AppStrings.t('FORGOT_PASSWORD'),
                    onPress: () => context.push('/forgot-password'),
                  ),
                ),

                // Blacklisted alert
                if (_blacklisted)
                  BcError(
                    message: AppStrings.t('IS_BLACKLISTED'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
