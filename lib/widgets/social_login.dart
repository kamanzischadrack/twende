// lib/widgets/social_login.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SocialLogin extends ConsumerStatefulWidget {
  final bool stayConnected;
  final VoidCallback? onSignInSuccess;
  final VoidCallback? onSignInError;
  final VoidCallback? onBlackListed;

  const SocialLogin({
    super.key,
    this.stayConnected = false,
    this.onSignInSuccess,
    this.onSignInError,
    this.onBlackListed,
  });

  @override
  ConsumerState<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends ConsumerState<SocialLogin> {
  void _showErrorDialog([String? message]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppStrings.t('ERROR'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message ?? AppStrings.t('LOGIN_ERROR'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppStrings.t('CLOSE'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSocialSignIn(String provider) async {
    try {
      final success = await ref.read(authProvider.notifier).socialSignIn({
        'socialSignInType': provider,
        'stayConnected': widget.stayConnected,
        'mobile': true,
      });

      if (success) {
        widget.onSignInSuccess?.call();
      } else {
        widget.onSignInError?.call();
        if (mounted) {
          _showErrorDialog();
        }
      }
    } catch (_) {
      widget.onSignInError?.call();
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  Widget _buildSocialIcon({
    required String assetPath,
    required double size,
    required IconData fallbackIcon,
    required Color fallbackColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            fallbackIcon,
            size: size * 0.8,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          // "OR" Divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFCFD8DC),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  AppStrings.t('OR'),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFCFD8DC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Social Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GOOGLE
              _buildSocialIcon(
                assetPath: 'assets/images/google-icon.png',
                size: 52,
                fallbackIcon: Icons.g_mobiledata,
                fallbackColor: Colors.red,
                onTap: () => _handleSocialSignIn('google'),
              ),

              // APPLE (visible on iOS or macOS)
              if (showApple) ...[
                const SizedBox(width: 16),
                _buildSocialIcon(
                  assetPath: 'assets/images/apple-icon.png',
                  size: 46,
                  fallbackIcon: Icons.apple,
                  fallbackColor: Colors.black,
                  onTap: () => _handleSocialSignIn('apple'),
                ),
              ],

              // FACEBOOK
              const SizedBox(width: 16),
              _buildSocialIcon(
                assetPath: 'assets/images/facebook-blue-icon.png',
                size: 46,
                fallbackIcon: Icons.facebook,
                fallbackColor: const Color(0xFF1877F2),
                onTap: () => _handleSocialSignIn('facebook'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
