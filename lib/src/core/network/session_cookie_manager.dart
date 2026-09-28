import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swr_pmis_mobile/src/core/config/environment.dart';

class SessionCookieManager {
  SessionCookieManager._(this.cookieJar, this.persistDirPath);

  final PersistCookieJar cookieJar;
  final String persistDirPath;

  CookieManager asInterceptor() => CookieManager(cookieJar);

  static Future<SessionCookieManager> create() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String cookiePath =
        '${appDocDir.path}/swr_pmis_cookies_${Environment.current.name}';
    final PersistCookieJar jar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage(cookiePath),
    );
    return SessionCookieManager._(jar, cookiePath);
  }

  Future<void> clearSessionCookies() async {
    await cookieJar.deleteAll();
    await cookieJar.delete(Environment.swrOriginUri);
    await cookieJar.delete(Uri.parse(Environment.swrBaseUrl));
  }
}
