import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/features/auth/data/auth_models.dart';
import 'package:sokolink/features/auth/data/auth_repository.dart';
import 'package:sokolink/features/auth/data/pin_service.dart';

enum AuthStatus {
  unknown,
  needsOtp,
  needsProfile,
  needsPinSetup,
  needsPinUnlock,
  authenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.phone,
    this.devCode,
    this.isOffline = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final String? phone;
  final String? devCode;
  final bool isOffline;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    String? phone,
    String? devCode,
    bool? isOffline,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      phone: phone ?? this.phone,
      devCode: devCode ?? this.devCode,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._pin) : super(const AuthState()) {
    bootstrap();
  }

  final AuthRepository _repo;
  final PinService _pin;

  Future<bool> _online() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> bootstrap() async {
    final online = await _online();
    final user = await _repo.restoreSession(online: online);
    final hasPin = await _pin.hasPin();

    // Session JWT conservée jusqu'au logout explicite (pas de re-OTP automatique).
    // À chaque démarrage froid : déverrouillage PIN local (zéro SMS).
    await _pin.setUnlocked(false);

    if (user == null) {
      state = AuthState(status: AuthStatus.needsOtp, isOffline: !online);
      return;
    }

    if (!hasPin) {
      state = AuthState(
        status: AuthStatus.needsPinSetup,
        user: user,
        isOffline: !online,
      );
      return;
    }

    state = AuthState(
      status: AuthStatus.needsPinUnlock,
      user: user,
      isOffline: !online,
    );
  }

  Future<void> refreshUser() async {
    final online = await _online();
    final user = await _repo.restoreSession(online: online);
    if (user == null) return;
    state = state.copyWith(user: user, isOffline: !online);
  }

  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(clearError: true, phone: phone);
    try {
      final data = await _repo.requestOtp(phone);
      state = state.copyWith(
        phone: data['phone']?.toString() ?? phone,
        devCode: data['devCode']?.toString(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _otpError(e));
      return false;
    }
  }

  String _otpError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 429) {
        return 'Trop de demandes. Patientez une minute avant de réessayer.';
      }
      if (code == 400 || code == 422) {
        return 'Numéro invalide. Format attendu : +243XXXXXXXXX.';
      }
      if (code != null && code >= 500) {
        return 'Service momentanément indisponible. Réessayez dans un instant.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Serveur injoignable. Vérifiez votre connexion et réessayez.';
      }
    }
    return 'Impossible d’envoyer l’OTP. Réessayez.';
  }

  Future<String> verifyOtp({
    required String code,
    String? fullName,
    String? companyName,
    String? province,
    List<String>? roles,
  }) async {
    state = state.copyWith(clearError: true);
    final phone = state.phone;
    if (phone == null) return 'missing_phone';
    try {
      final data = await _repo.verifyOtp(
        phone: phone,
        code: code,
        fullName: fullName,
        companyName: companyName,
        province: province,
        roles: roles,
      );

      if (data['needsProfile'] == true) {
        state = state.copyWith(status: AuthStatus.needsProfile, phone: phone);
        return 'needs_profile';
      }

      final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      final hasPin = await _pin.hasPin();
      state = AuthState(
        status: hasPin ? AuthStatus.needsPinUnlock : AuthStatus.needsPinSetup,
        user: user,
        phone: phone,
      );
      return hasPin ? 'needs_pin_unlock' : 'needs_pin_setup';
    } catch (_) {
      state = state.copyWith(error: 'Code OTP incorrect ou expiré.');
      return 'error';
    }
  }

  Future<bool> setupPin(String pin) async {
    if (pin.length < 4) {
      state = state.copyWith(error: 'Le code PIN doit contenir 4 chiffres minimum.');
      return false;
    }
    await _pin.setPin(pin);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      phone: state.phone,
    );
    return true;
  }

  Future<bool> unlockWithPin(String pin) async {
    state = state.copyWith(clearError: true);
    final locked = await _pin.lockRemaining();
    if (locked != null) {
      final mins = locked.inMinutes + 1;
      state = state.copyWith(
        error: 'PIN verrouillé. Réessayez dans $mins min.',
      );
      return false;
    }
    final ok = await _pin.verifyPin(pin);
    if (!ok) {
      final again = await _pin.lockRemaining();
      state = state.copyWith(
        error: again != null
            ? 'Trop d’essais. PIN verrouillé 5 minutes.'
            : 'Code PIN incorrect.',
      );
      return false;
    }
    await _pin.setUnlocked(true);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      phone: state.phone,
      isOffline: state.isOffline,
    );
    return true;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.needsOtp);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(pinServiceProvider),
  );
});
