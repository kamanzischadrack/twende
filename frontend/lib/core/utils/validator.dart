// lib/core/utils/validator.dart

class Validator {
  Validator._();

  static bool isEmail(String value) {
    if (value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  static bool isPhone(String value) {
    if (value.isEmpty) return false;
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    return phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''));
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isEmail(value)) return 'Invalid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return "Passwords don't match";
    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    if (!isPhone(value)) return 'Invalid phone number';
    return null;
  }
}

typedef AppValidator = Validator;
