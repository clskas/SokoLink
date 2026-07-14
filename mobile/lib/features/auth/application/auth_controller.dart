import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/features/auth/data/auth_models.dart';
import 'package:sokolink/features/auth/data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    restore();
  }

  final AuthRepository _repo;

  Future<void> restore() async {
    final user = await _repo.restore();
    state = AuthState(
      status: user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      user: user,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _message(e),
      );
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> body) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _repo.register(body);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _message(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _message(Object e) {
    final text = e.toString();
    if (text.contains('Cet email')) return 'Cet email est déjà utilisé';
    if (text.contains('incorrect')) return 'Email ou mot de passe incorrect';
    return 'Une erreur est survenue. Vérifiez votre connexion.';
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);
