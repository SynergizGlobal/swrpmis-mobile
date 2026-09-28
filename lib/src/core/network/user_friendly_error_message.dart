import 'package:dio/dio.dart';

String userFriendlyErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out. Please try again.';
    case DioExceptionType.connectionError:
      return 'No internet connection. Please check your network.';
    case DioExceptionType.badResponse:
      final int? code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'Session expired. Please sign in again.';
      }
      if (code != null && code >= 500) {
        return 'Server error. Please try again later.';
      }
      final dynamic data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Something went wrong (${code ?? 'error'}).';
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    case DioExceptionType.badCertificate:
      return 'Secure connection failed.';
    case DioExceptionType.unknown:
      return error.message?.isNotEmpty == true
          ? error.message!
          : 'Unexpected network error.';
    case DioExceptionType.transformTimeout:
      return 'Request timed out while processing the response.';
  }
}
