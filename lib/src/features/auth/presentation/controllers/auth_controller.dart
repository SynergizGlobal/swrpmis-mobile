import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/core/network/session_cookie_manager.dart';
import 'package:swr_pmis_mobile/src/core/result/failure.dart';
import 'package:swr_pmis_mobile/src/core/result/result.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/providers/auth_token_provider.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(
    ref,
    ref.watch(loginUseCaseProvider),
    ref.watch(authLocalDataSourceProvider),
    ref.watch(authRemoteDataSourceProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(
    this._ref,
    this._loginUseCase,
    this._local,
    this._remote,
  ) : super(const AsyncData<AuthSession?>(null));

  final Ref _ref;
  final LoginUseCase _loginUseCase;
  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  bool _autoLoginAttempted = false;

  void _syncAuthToken(AuthSession? session) {
    final String token = session?.token.trim() ?? '';
    _ref.read(authTokenProvider.notifier).state =
        token.isEmpty ? null : token;
  }

  Future<Failure?> tryAutoLoginIfRemembered() async {
    if (_autoLoginAttempted) {
      return null;
    }
    _autoLoginAttempted = true;
    final AuthLocalSnapshot snap = await _local.readSnapshot();
    final String userId = snap.userId?.trim() ?? '';
    final String password = snap.password ?? '';
    if (!snap.rememberMe || userId.isEmpty || password.isEmpty) {
      return null;
    }
    return login(userId: userId, password: password, rememberMe: true);
  }

  Future<Failure?> login({
    required String userId,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    final SessionCookieManager cookieManager =
        await _ref.read(sessionCookieManagerProvider.future);
    await cookieManager.clearSessionCookies();
    final Result<AuthSession> result = await _loginUseCase(
      userId: userId,
      password: password,
    );
    return result.fold<Future<Failure?>>(
      (Failure failure) async {
        state = const AsyncData<AuthSession?>(null);
        _syncAuthToken(null);
        return failure;
      },
      (AuthSession session) async {
        state = AsyncData<AuthSession?>(session);
        _syncAuthToken(session);
        await _local.saveAfterLogin(
          rememberMe: rememberMe,
          userId: userId,
          password: password,
          session: session,
        );
        return null;
      },
    );
  }

  Future<void> logout() async {
    try {
      await _remote.logoutSession();
    } catch (_) {}
    try {
      final cookieManager =
          await _ref.read(sessionCookieManagerProvider.future);
      await cookieManager.clearSessionCookies();
    } catch (_) {}
    await _local.clearAll();
    _syncAuthToken(null);
    state = const AsyncData<AuthSession?>(null);
  }
}
