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
  static const String utilityShiftingLocationFilterPath =
      '/utility-shifting/ajax/getLocationListFilter';
  static const String utilityShiftingCategoryFilterPath =
      '/utility-shifting/ajax/getUtilityCategoryListFilter';
  static const String utilityShiftingTypeFilterPath =
      '/utility-shifting/ajax/getUtilityTypeListFilter';
  static const String utilityShiftingStatusFilterPath =
      '/utility-shifting/ajax/getStatusListFilter';
  static const String utilityShiftingListPath =
      '/utility-shifting/ajax/getUtilityShiftingList';
  static const String utilityShiftingUploadsListPath =
      '/utility-shifting/ajax/getUtilityShiftingUploadsList';
  static const String utilityShiftingTemplatePath =
      '/utility-shifting/utility-shifting-template';
  static const String utilityShiftingUploadPath =
      '/utility-shifting/upload-utility-shifting';
  static const String utilityShiftingAddFormPath =
      '/utility-shifting/ajax/form/add-utility-shifting';
  static const String utilityShiftingReqStageListPath =
      '/utility-shifting/ajax/getReqStageListForUSForm';
  static const String utilityShiftingImpactedElementListPath =
      '/utility-shifting/ajax/getImpactedElementListForUSForm';
  static const String utilityShiftingAddPath =
      '/utility-shifting/addUtilityShifting';
  static const String utilityShiftingGetPath =
      '/utility-shifting/ajax/get-utility-shifting';
  static const String utilityShiftingUpdatePath =
      '/utility-shifting/updateUtilityShifting';
  static const String materialReceiptListPath =
      '/material-receipt/ajax/getMaterialReceipts';
  static const String materialReceiptFilterOptionsPath =
      '/material-receipt/ajax/getMaterialReceiptFilterOptions';

  static String materialReceiptViewPath(String receiptId) =>
      '/material-receipt/view/${Uri.encodeComponent(receiptId.trim())}';

  static String materialReceiptDownloadDocumentPath(int docId) =>
      '/material-receipt/download-document/$docId';

  static const String materialReceiptDropdownProjectsPath =
      '/material-receipt/dropdown-projects';
  static const String materialReceiptDropdownMaterialsPath =
      '/material-receipt/dropdown-materials';
  static const String materialReceiptDropdownSectionsPath =
      '/material-receipt/dropdown-sections';
  static const String materialReceiptDropdownContractsPath =
      '/material-receipt/dropdown-contracts';
  static const String materialReceiptDocumentsByMaterialPath =
      '/material-receipt/documents-by-material';
  static const String materialReceiptSavePath = '/material-receipt/save';
  static const String materialReceiptDownloadTemplatePath =
      '/material-receipt/download-template';

  static const String qualityTestObligationsPath =
      '/api/quality/test-obligations';

  static String qualityTestObligationDetailPath(int id) =>
      '/api/quality/test-obligations/$id';

  static String qualityTestObligationTraceabilityPath(int id) =>
      '/traceability/test-obligation/$id';

  /// Rich obligation payload used by NCR reference panel.
  static String qualityTestObligationDetailViewPath(int id) =>
      '/api/quality/test-obligations/$id/detail';

  static const String ncrObservationsPath = '/api/quality/ncr-observations';

  static String ncrObservationDetailPath(int id) =>
      '/api/quality/ncr-observations/$id';

  static String ncrObservationAttachmentsPath(int id) =>
      '/api/quality/ncr-observations/$id/attachments';

  static String ncrObservationVerifyPath(int id) =>
      '/api/quality/ncr-observations/$id/verify';

  static const String rfiMenuAccessPath = '/rfi/menu-access';
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

  /// SWR backend: `@RequestMapping("/swr/device-tokens")`.
  static const String deviceTokenRegisterPath = '/swr/device-tokens/register';
  static const String deviceTokenDeactivatePath =
      '/swr/device-tokens/deactivate';

  static const String rdsoCategoriesPath = '/api/rdso/categories';
  static const String rdsoDrawingsRegisterPath = '/api/rdso/drawings/register';
  static const String rdsoDrawingsSearchPath = '/api/rdso/drawings/search';

  static String rdsoFileViewPath(String fileId) =>
      '/api/rdso/files/$fileId/view';

  static String rdsoFileDownloadPath(String fileId) =>
      '/api/rdso/files/$fileId/download';

  static String rdsoCategorySubheadsPath(String categoryId) =>
      '/api/rdso/categories/$categoryId/subheads';

  static String rdsoSubheadDrawingsPath(String subheadId) =>
      '/api/rdso/subheads/$subheadId/drawings';

  static String rdsoDrawingFilesPath(String drawingId) =>
      '/api/rdso/drawings/$drawingId/files';

  static String rdsoDrawingPostsPath(String drawingId) =>
      '/api/rdso/drawings/$drawingId/posts';

  static const String rdsoPostsPath = '/api/rdso/posts';

  static String rdsoFileSendMailPath(String fileId) =>
      '/api/rdso/files/$fileId/send-mail';

  static const String rdsoCrawlRunsPath = '/api/rdso/admin/crawl/runs';

  static String rdsoCrawlRunLogsPath(String runId) =>
      '/api/rdso/admin/crawl/runs/$runId/logs';

  static String rdsoCrawlRunCancelPath(String runId) =>
      '/api/rdso/admin/crawl/runs/$runId/cancel';

  static const String rdsoCrawlStartPath = '/api/rdso/admin/crawl';

  static const String mailInboxPath = '/api/mail/inbox';
  static const String mailDraftsPath = '/api/mail/drafts';
  static const String mailSentPath = '/api/mail/sent';
  static const String mailTrashPath = '/api/mail/trash';
  static const String mailStarredPath = '/api/mail/starred';
  static const String mailDashboardPath = '/api/mail/dashboard';
  static const String mailLabelsPath = '/api/labels';
  static const String mailRecipientsSearchPath = '/api/mail/recipients/search';
  static const String mailGenerateReferencePath = '/api/mail/generate-reference';
  static const String mailDraftPath = '/api/mail/draft';
  static const String mailSendPath = '/api/mail/send';
  static const String documentsRepositoryPath = '/api/documents/repository';

  static String mailLabelMailsPath(String labelName) =>
      '/api/labels/label/${Uri.encodeComponent(labelName.trim())}';

  static String mailStarPath(int mailId) => '/api/mail/$mailId/star';

  static String mailTrashActionPath(int mailId) => '/api/mail/$mailId/trash';

  static String mailRestorePath(int mailId) => '/api/mail/$mailId/restore';

  static String mailPermanentDeletePath(int mailId) =>
      '/api/mail/$mailId/permanent';

  static String documentsRepositoryFolderPath(int folderId) =>
      '/api/documents/repository/folder/$folderId';

  static const String documentsRepositoryCreateFolderPath =
      '/api/documents/repository/folder';

  static const String documentsRepositoryUploadPath =
      '/api/documents/repository/upload';

  static String documentsRepositoryRenamePath(int id) =>
      '/api/documents/repository/$id/rename';

  static String documentsRepositoryDownloadPath(int id) =>
      '/api/documents/repository/$id/download';

  static String documentsRepositoryDeletePath(int id) =>
      '/api/documents/repository/$id';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
