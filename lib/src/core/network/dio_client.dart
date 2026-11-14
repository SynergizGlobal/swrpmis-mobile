import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/auth_interceptor.dart';
import 'package:swr_pmis_mobile/src/core/network/session_cookie_manager.dart';
import 'package:swr_pmis_mobile/src/core/network/session_cookie_protection_interceptor.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/providers/auth_token_provider.dart';

/// Set to `true` by the Dio error interceptor on 401/403.  The auth layer
/// watches this and triggers logout (FCM deregister, cookie clear, etc.).
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final sessionCookieManagerProvider =
    FutureProvider<SessionCookieManager>((ref) {
  ref.watch(appConfigProvider.select((AppConfig config) => config.baseUrl));
  return SessionCookieManager.create();
});

final dioProvider = Provider<Dio>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  final SessionCookieManager sessionCookieManager =
      ref.watch(sessionCookieManagerProvider).requireValue;

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: appConfig.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.connectTimeout,
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        maxWidth: 120,
        filter: shouldLogDioTraffic,
      ),
    );
  }

  dio.interceptors.add(
    AuthInterceptor(() => ref.read(authTokenProvider)),
  );
  dio.interceptors.add(sessionCookieManager.asInterceptor());
  dio.interceptors.add(const SessionCookieProtectionInterceptor());
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        if (error.requestOptions.extra['skipAuth'] == true) {
          handler.next(error);
          return;
        }
        final int? code = error.response?.statusCode;
        if (code == 401 || code == 403) {
          final String path = error.requestOptions.path;
          if (!path.contains('/login') && !path.contains('/logout')) {
            ref.read(sessionExpiredProvider.notifier).state = true;
          }
        }
        handler.next(
          error.copyWith(message: userFriendlyErrorMessage(error)),
        );
      },
    ),
  );

  return dio;
});

/// Debug logging skips binary downloads (images, PDFs). Printing a
/// multi-megabyte byte list on the UI thread froze the screen for seconds.
bool shouldLogDioTraffic(RequestOptions options, FilterArgs args) {
  if (options.responseType == ResponseType.bytes ||
      options.responseType == ResponseType.stream) {
    return false;
  }
  return !(args.isResponse && args.data is List<int>);
}
