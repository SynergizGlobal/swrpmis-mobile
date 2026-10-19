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
  static const String updateFormsPath = '/forms/api/getUpdateForms';
  static const String issueContractsFilterPath =
      '/issue/ajax/getContractsListFilterInIssue';
  static const String issueHodFilterPath =
      '/issue/ajax/getHODListFilterInIssue';
  static const String issueDepartmentsFilterPath =
      '/issue/ajax/getDepartmentsListFilterInIssue';
  static const String issueCategoryFilterPath =
      '/issue/ajax/getCategoryListFilterInIssue';
  static const String issueStatusFilterPath =
      '/issue/ajax/getStatusListFilterInIssue';
  static const String issueListPath = '/issue/ajax/getIssuesList';
  static const String issueAddFormPath = '/issue/ajax/form/add-issue-form';
  static const String issueDetailPath = '/issue/ajax/form/get-issue/issue';
  static const String issueFormContractsPath =
      '/issue/ajax/getContractsListForIssuesForm';
  static const String issueFormCategoriesPath =
      '/issue/ajax/getIssueCategoryListForIssuesForm';
  static const String issueFormTitlesPath =
      '/issue/ajax/getIssueTitlesListForIssuesForm';
  static const String issueFormStructuresPath =
      '/issue/ajax/getStructureListForIssue';
  static const String issueFormComponentsPath =
      '/issue/ajax/getComponentListForIssue';
  static const String designContractFilterPath =
      '/design/ajax/getContractListFilterInDesign';
  static const String designStructureFilterPath =
      '/design/ajax/getStructureListFilterInDesign';
  static const String designDrawingTypeFilterPath =
      '/design/ajax/getDrawingTypeListFilterInDesign';
  static const String designListPath = '/design/ajax/getDesignsList';
  static const String designUploadsListPath =
      '/design/ajax/getDesignUploadsList';
  static const String designDownloadTemplatePath =
      '/design/download-design-template';
  static const String designUploadDesignsPath = '/design/upload-designs';
  static const String designUploadDownloadPath =
      '/design/ajax/downloadUploadedDesignData';
  static const String materialRfiListPath = '/rfi/api/materialRfi/list';
  static const String workRfiListPath = '/rfi/api/workRfi/list';
  static const String workRfiCreatePath = '/rfi/api/workRfi/create';
  static const String qualityRfiListPath = '/rfi/api/qualityRfi/list';
  static const String newActivitiesUpdatePath = '/newActivitiesUpdate';
  static const String contractListForProjectPath = '/getContractListForProject';
  static const String structureTypesInActivitiesPath =
      '/ajax/getStructureTypesInActivitiesUpdate';
  static const String activitiesUpdateStructuresPath =
      '/ajax/getNewActivitiesUpdateStructures';
  static const String activitiesUpdateComponentsPath =
      '/ajax/getNewActivitiesUpdateComponentsList';
  static const String activitiesUpdateComponentIdsPath =
      '/ajax/getNewActivitiesUpdateComponentIdsList';
  static const String activitiesUpdateActivitiesPath =
      '/ajax/getNewActivitiesUpdateActivitiesList';
  static const String rfiTypeDescriptionsPath = '/rfi/rfi-type-descriptions';
  static const String workRepresentativesPath = '/api/work-representatives';
  static const String workRfiEnclosuresPath = '/rfi/api/enclosures';

  static String workRfiPath(int id) => '/rfi/api/workRfi/$id';
  static const String rfiFilterCategoryPath = '/rfi/filter-rfi-category';
  static const String rfiFilterProjectPath = '/rfi/filter-project';
  static const String rfiFilterContractPath = '/rfi/filter-contract';
  static const String rfiFilterStructureTypePath = '/rfi/filter-structure-type';
  static const String rfiFilterStructurePath = '/rfi/filter-structure';
  static const String rfiFilterItemPath = '/rfi/filter-item';
  static const String rfiFilterMaterialPath = '/rfi/filter-material';
  static const String rfiFilterQualitySafetyPath = '/rfi/filter-quality-safety';
  static const String rfiDetailsPath = '/rfi/rfi-details';
  static String rfiDetailsByIdPath(int id) => '/rfi/rfi-details/$id';
  static const String rfiInspectionAccessPath = '/inspection-access';
  static const String checkUserSignaturePath = '/api/checkUserSignature';
  static const String rfiSaveDraftPath = '/rfi/saveDraft';
  static const String rfiUploadSiteImagePath =
      '/rfi/inspection/uploadSiteImage';
  static const String rfiUploadEnclosurePath = '/rfi/upload';
  static const String rfiSaveChecklistPath = '/rfi/saveChecklist';
  static const String rfiChecklistItemsPath =
      '/api/v1/enclouser/checklist-items';
  static const String rfiFinalSubmitPath = '/rfi/finalSubmit';
  static const String rfiDeleteSiteImagePath = '/rfi/delete-site-img';
  static const String rfiDeleteEnclosurePath = '/rfi/enclosure/files';
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
  static const String rfiInspectionCountPath = '/rfi/inspection-count';
  static const String rfiStatusCountsPath = '/rfi/status-counts';
  static const String rfiProjectNamesPath = '/rfi/projectNames';
  static const String rfiContractNamesPath = '/rfi/contractNames';
  static const String rfiLayerRangePath =
      '/rfi/api/ajax/getLayerRangeForStructureType';
  static const String rfiAssignedExecutiveLogsPath =
      '/rfi/getAssinedExecutiveLogs';

  static String rfiAssignExecutiveDeletePath(int id) =>
      '/rfi/assignExecutive/delete/$id';

  static const String rfiEnclosureListPath = '/api/v1/enclouser/enclosure_list';
  static const String rfiEnclosureNamesPath = '/api/v1/enclouser/names';
  static const String rfiEnclosureByActionPath = '/api/v1/enclouser/by-action';
  static const String rfiEnclosureSubmitPath = '/api/v1/enclouser/submit';
  static const String rfiDescriptionsPath = '/rfi/get-descriptions';
  static const String rfiDescriptionSavePath = '/rfi/description-save';

  static String rfiEnclosureChecklistPath(int id) =>
      '/api/v1/enclouser/get/$id';

  static String rfiEnclosureUpdatePath(int id) =>
      '/api/v1/enclouser/updateEnclosureName/$id';

  static String rfiEnclosureDeletePath(int id) =>
      '/api/v1/enclouser/deleteEncloserName/$id';

  static String rfiChecklistDescriptionsPath(int enclosureId) =>
      '/api/v1/enclouser/addChecklistDescriptions/$enclosureId';

  static String rfiChecklistUpdatePath(int id) =>
      '/api/v1/enclouser/update/$id';

  static String rfiChecklistDeletePath(int id) =>
      '/api/v1/enclouser/delete/$id';

  static String rfiDescriptionUpdatePath(int id) =>
      '/rfi/description-update/$id';

  static String rfiDescriptionDeletePath(int id) =>
      '/rfi/delete-rfi-description/$id';

  static const String deviceTokenRegisterPath = 'wcr/device-tokens/register';
  static const String deviceTokenDeactivatePath =
      'wcr/device-tokens/deactivate';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
