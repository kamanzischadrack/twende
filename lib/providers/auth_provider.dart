// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && user!.accessToken != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final loggedIn = await UserService.instance.isLoggedIn();
    if (loggedIn) {
      final user = await UserService.instance.getStoredUser();
      state = state.copyWith(user: user, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await UserService.instance.signIn({
        'email': email,
        'password': password,
      });
      if (result.status == 200 && result.user != null) {
        state = state.copyWith(user: result.user, isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid credentials',
        clearUser: true,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearUser: true,
      );
      return false;
    }
  }

  Future<bool> socialSignIn(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await UserService.instance.socialSignIn(data);
      if (result.status == 200 && result.user != null) {
        state = state.copyWith(user: result.user, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Sign-in failed', clearUser: true);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), clearUser: true);
      return false;
    }
  }

  Future<void> signOut() async {
    await UserService.instance.signOut();
    state = const AuthState();
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider).user,
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isAuthenticated,
);
