class ApiConstants {
  const ApiConstants._();

  static const String loginPath = '/login';
  static const String logoutPath = '/logout';
  static const String sessionCheckPath = '/session-check';
  static const String forgotSendOtpPath = '/api/forgot/send-otp';
  static const String forgotVerifyOtpPath = '/api/forgot/verify-otp';
  static const String forgotResetPasswordPath = '/api/forgot/reset-password';
  static const String projectsListPath = '/projects/api/getProjectList';
  static const String projectTypesPath = '/projects/api/projectTypes';
  static const String usersByTypePath = '/projects/api/usersByType';
  static const String projectListByTypePath =
      '/projects/api/getProjectListByType';
  static const String executionProgressPath = '/execution/progress';
  static const String reportFormsPath = '/forms/api/getReportForms';
  static const String materialRfiListPath = '/rfi/api/materialRfi/list';
  static const String workRfiListPath = '/rfi/api/workRfi/list';
  static const String qualityRfiListPath = '/rfi/api/qualityRfi/list';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
