import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/mock_data_service.dart';

class AuthState {
  final bool isLoading;
  final User? currentUser;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    User? currentUser,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    checkSavedSession();
  }

  Future<void> checkSavedSession() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_user_email');
    if (email != null && email.isNotEmpty) {
      final user = MockDataService().employees.firstWhere(
        (e) => e.email.toLowerCase() == email.toLowerCase(),
        orElse: () => MockDataService().employees.first,
      );
      state = state.copyWith(isLoading: false, currentUser: user);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600)); // Network simulation

    final found = MockDataService().employees.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );

    if (found.isNotEmpty) {
      final user = found.first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_email', user.email);
      await prefs.setString('auth_token', 'jwt_mock_token_${user.id}');
      state = state.copyWith(isLoading: false, currentUser: user);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid email or password credentials',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user_email');
    await prefs.remove('auth_token');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
