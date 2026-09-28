import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  static final Options _loginOptions = Options(
    extra: <String, dynamic>{
      'skipAuth': true,
      'allowSetCookie': true,
    },
    contentType: 'application/json',
    responseType: ResponseType.json,
    followRedirects: false,
    validateStatus: _okOrClientError,
    headers: <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  static final Options _unauthenticatedOptions = Options(
    extra: const <String, dynamic>{
      'skipAuth': true,
      'allowSetCookie': true,
    },
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    validateStatus: _okOrClientError,
  );

  static bool _okOrClientError(int? status) {
    return status != null && status >= 200 && status < 500;
  }

  Future<AuthSessionModel> login({
    required String userId,
    required String password,
  }) async {
    await _primeLoginSession();

    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.loginPath,
      data: <String, String>{
        'userId': userId,
        'password': password,
      },
      options: _loginOptions,
    );

    final int status = response.statusCode ?? 0;
    final Map<String, dynamic> body = _asMap(response.data);
    final String errorMessage = _loginErrorMessage(body);

    if (status == 401 || status == 400 || status == 403) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage,
      );
    }

    if (status != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage,
      );
    }

    if (body['userId'] == null && body['user_id'] == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: errorMessage,
      );
    }

    final String? sessionId = _sessionIdFrom(
      setCookie: response.headers['set-cookie'],
    );
    final AuthSessionModel parsed = AuthSessionModel.fromJson(body);
    return AuthSessionModel(
      token: sessionId ?? parsed.token,
      userId: parsed.userId.isNotEmpty ? parsed.userId : userId,
      userName: parsed.userName.isNotEmpty ? parsed.userName : userId,
      emailId: parsed.emailId,
      userRoleNameFk: parsed.userRoleNameFk,
      userTypeFk: parsed.userTypeFk,
      departmentFk: parsed.departmentFk,
      designation: parsed.designation,
    );
  }

  Future<void> _primeLoginSession() async {
    try {
      await _dio.get<dynamic>(
        ApiConstants.loginPath,
        options: Options(
          extra: const <String, dynamic>{
            'skipAuth': true,
            'allowSetCookie': true,
          },
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (int? status) => status != null && status < 500,
        ),
      );
    } catch (_) {}
  }

  Future<void> sendForgotPasswordOtp({required String emailId}) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotSendOtpPath,
      data: <String, dynamic>{'emailId': emailId},
      options: _unauthenticatedOptions,
    );
  }

  Future<void> verifyForgotPasswordOtp({
    required String emailId,
    required String otp,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotVerifyOtpPath,
      data: <String, dynamic>{'emailId': emailId, 'otp': otp},
      options: _unauthenticatedOptions,
    );
  }

  Future<void> resetForgotPassword({
    required String emailId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      ApiConstants.forgotResetPasswordPath,
      data: <String, dynamic>{
        'emailId': emailId,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      options: _unauthenticatedOptions,
    );
  }

  Future<void> logoutSession() async {
    await _dio.post<dynamic>(
      ApiConstants.logoutPath,
      options: Options(
        extra: const <String, dynamic>{
          'skipAuth': true,
          'allowSetCookie': true,
        },
        validateStatus: (int? status) => status != null && status < 500,
      ),
    );
  }

  static String _loginErrorMessage(Map<String, dynamic> body) {
    const String fallback = 'Invalid user name or password.';
    for (final String key in <String>['errorMessage', 'message', 'error']) {
      final String text = (body[key] ?? '').toString().trim();
      if (text.isEmpty || text == 'AUTHENTICATION_FAILED') {
        continue;
      }
      return text;
    }
    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }

  static String? _sessionIdFrom({required List<String>? setCookie}) {
    if (setCookie == null || setCookie.isEmpty) {
      return null;
    }
    final RegExp cookieRe = RegExp(
      r'JSESSIONID=([^;]+)',
      caseSensitive: false,
    );
    for (final String header in setCookie) {
      final Match? match = cookieRe.firstMatch(header);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});
