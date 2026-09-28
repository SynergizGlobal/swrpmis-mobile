import 'package:dio/dio.dart';

class SessionCookieProtectionInterceptor extends Interceptor {
  const SessionCookieProtectionInterceptor();

  static bool _allowsSetCookie(RequestOptions options) {
    if (options.extra['allowSetCookie'] == true) {
      return true;
    }
    if (options.extra['skipAuth'] == true) {
      final String path = options.path.toLowerCase();
      return path.contains('/login') ||
          path.contains('/forgot') ||
          path.contains('/logout');
    }
    return false;
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_allowsSetCookie(response.requestOptions)) {
      response.headers.removeAll('set-cookie');
    }
    handler.next(response);
  }
}
