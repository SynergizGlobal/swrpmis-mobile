import 'package:dio/dio.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';

String rfiInspectionErrorMessage(Object error) {
  if (error is DioException) {
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}
