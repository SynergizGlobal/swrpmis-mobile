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
  static const String rfiFilterCategoryPath = '/rfi/filter-rfi-category';
  static const String rfiFilterProjectPath = '/rfi/filter-project';
  static const String rfiFilterContractPath = '/rfi/filter-contract';
  static const String rfiFilterStructureTypePath = '/rfi/filter-structure-type';
  static const String rfiFilterStructurePath = '/rfi/filter-structure';
  static const String rfiFilterItemPath = '/rfi/filter-item';
  static const String rfiFilterMaterialPath = '/rfi/filter-material';
  static const String rfiFilterQualitySafetyPath = '/rfi/filter-quality-safety';
  static const String rfiDetailsPath = '/rfi/rfi-details';
  static const String rfiBulkSubmitNoRfiRequiredPath =
      '/rfi/bulkSubmitNoRfiRequired';
  static const String rfiLogListPath = '/api/rfiLog/getAllRfiLogDetails';
  static const String rfiLogReportPath = '/api/rfiLog/getRfiReportDetails';
  static const String rfiLogPreviewFilesPath = '/api/rfiLog/previewFiles';
  static const String rfiLogPdfDownloadPath = '/api/rfiLog/pdf/download';
  static const String validationFilterCategoryPath =
      '/api/validation/filter-rfi-category';
  static const String validationFilterProjectPath =
      '/api/validation/filter-project';
  static const String validationFilterContractPath =
      '/api/validation/filter-contract';
  static const String validationListPath = '/api/validation/getRfiValidations';
  static const String validationValidatePath = '/api/validation/validate';
  static const String getRfiReportDetail = '/api/validation/getRfiReportDetail';
  static const String rfiProjectNamesPath = '/rfi/projectNames';
  static const String rfiContractNamesPath = '/rfi/contractNames';
  static const String rfiAssignedExecutiveLogsPath =
      '/rfi/getAssinedExecutiveLogs';

  static String rfiAssignExecutiveDeletePath(int id) =>
      '/rfi/assignExecutive/delete/$id';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
