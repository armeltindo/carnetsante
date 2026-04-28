import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/hive_database.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(user: Supabase.instance.client.auth.currentUser));

  final _supabase = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(user: response.user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e.message),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de connexion');
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name},
      );
      state = state.copyWith(user: response.user, isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapAuthError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur d\'inscription');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await HiveDatabase.clearAll();
    state = const AuthState();
  }

  String _mapAuthError(String msg) {
    if (msg.contains('Invalid login')) return 'Email ou mot de passe incorrect';
    if (msg.contains('Email not confirmed')) return 'Confirmez votre email';
    if (msg.contains('already registered')) return 'Email déjà utilisé';
    if (msg.contains('Password should')) return 'Mot de passe trop court (min. 6 caractères)';
    return msg;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
