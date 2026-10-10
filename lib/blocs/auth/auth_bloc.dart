import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({
    required this._authService,
  }) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileRequested>(_onProfileRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.login(
        identifier: event.identifier,
        password: event.password,
      );

      final profile = await _authService.getCurrentProfile();

      if (profile == null) {
        await _authService.logout();
        emit(const AuthError('Profil akun tidak ditemukan.'));
        return;
      }

      final status = profile['status']?.toString().toLowerCase();

      if (status != 'active') {
        await _authService.logout();

        if (status == 'pending') {
          emit(const AuthError(
            'Akun kamu masih menunggu persetujuan admin.',
          ));
        } else if (status == 'blocked') {
          emit(const AuthError(
            'Akun kamu diblokir. Hubungi admin.',
          ));
        } else {
          emit(const AuthError(
            'Status akun tidak valid. Hubungi admin.',
          ));
        }

        return;
      }

      final role = profile['role']?.toString().toLowerCase();
      const allowedRoles = {'admin', 'pengurus', 'pengasuh'};

      if (role == null || !allowedRoles.contains(role)) {
        await _authService.logout();
        emit(const AuthError(
          'Role akun tidak valid. Hubungi admin.',
        ));
        return;
      }

      emit(AuthAuthenticated(profile: profile));
    } catch (error) {
      emit(AuthError(_loginErrorMessage(error)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthError(
        'Gagal logout. Silakan coba lagi.',
      ));
    }
  }

  Future<void> _onProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final profile = await _authService.getCurrentProfile();

      if (profile == null) {
        await _authService.logout();
        emit(const AuthUnauthenticated());
        return;
      }

      final status = profile['status']?.toString().toLowerCase();
      final role = profile['role']?.toString().toLowerCase();

      const allowedRoles = {'admin', 'pengurus', 'pengasuh'};

      if (status != 'active' ||
          role == null ||
          !allowedRoles.contains(role)) {
        await _authService.logout();
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(profile: profile));
    } catch (_) {
      emit(const AuthError(
        'Gagal mengambil profil akun. Silakan coba lagi.',
      ));
    }
  }

  String _loginErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('username tidak ditemukan')) {
      return 'Username tidak ditemukan.';
    }

    if (message.contains('invalid login credentials')) {
      return 'Email/username atau password salah.';
    }

    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi.';
    }

    if (message.contains('network') ||
        message.contains('socketexception')) {
      return 'Koneksi internet bermasalah.';
    }

    if (error is AuthException) {
      return error.message;
    }

    return 'Login gagal. Periksa data akun dan koneksi internet.';
  }
}