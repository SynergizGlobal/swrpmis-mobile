enum RfiUserRole {
  superUser,
  contractor,
  contractorRep,
  engineer,
  hod,
  dyHod,
  dyHodEngineer,
  itAdmin,
  unknown,
}

class RfiUserRoleResolver {
  const RfiUserRoleResolver._();

  static RfiUserRole fromFields({
    required String userTypeFk,
    required String userRoleNameFk,
  }) {
    final String userType = userTypeFk.trim();
    final String roleName = userRoleNameFk.trim();

    if (roleName == 'Data Admin') {
      if (userType == 'Officer (Jr./Sr. Scale)') {
        return RfiUserRole.dyHodEngineer;
      }
      return RfiUserRole.dyHod;
    }
    if (roleName == 'IT Admin') {
      return RfiUserRole.itAdmin;
    }
    if (roleName == 'Super User') {
      return RfiUserRole.superUser;
    }
    if (userType == 'Contractor') {
      return RfiUserRole.contractor;
    }
    if (userType == 'Contractor Rep') {
      return RfiUserRole.contractorRep;
    }
    if (userType == 'Officer (Jr./Sr. Scale)') {
      return RfiUserRole.engineer;
    }
    if (userType == 'HOD') {
      return RfiUserRole.hod;
    }
    return RfiUserRole.unknown;
  }
}

extension RfiUserRolePermissions on RfiUserRole {
  bool get canCreateRfi =>
      this == RfiUserRole.contractor || this == RfiUserRole.itAdmin;

  bool get canViewInspection =>
      this == RfiUserRole.hod ||
      this == RfiUserRole.engineer ||
      this == RfiUserRole.contractor ||
      this == RfiUserRole.contractorRep ||
      this == RfiUserRole.dyHod ||
      this == RfiUserRole.dyHodEngineer ||
      this == RfiUserRole.itAdmin;

  bool get canViewRfiLog => this != RfiUserRole.unknown;

  bool get canViewValidation =>
      this == RfiUserRole.hod ||
      this == RfiUserRole.engineer ||
      this == RfiUserRole.dyHod ||
      this == RfiUserRole.dyHodEngineer ||
      this == RfiUserRole.itAdmin;

  bool get canAssignExecutive =>
      this == RfiUserRole.engineer ||
      this == RfiUserRole.dyHodEngineer ||
      this == RfiUserRole.hod ||
      this == RfiUserRole.dyHod ||
      this == RfiUserRole.itAdmin;

  bool get canViewInspectionReferenceForm => this == RfiUserRole.itAdmin;

  bool canDeleteRfi(String status) {
    if (this == RfiUserRole.itAdmin) {
      return true;
    }
    if (this != RfiUserRole.contractor) {
      return false;
    }
    final String s = status.trim().toUpperCase();
    return s == 'CREATED' ||
        s == 'OPEN' ||
        s == 'UPDATED' ||
        s == 'RESCHEDULED' ||
        s == 'REASSIGNED';
  }

  bool canStartInspection(String status) {
    final String s = status.toUpperCase();
    if (this == RfiUserRole.contractorRep) {
      return s == 'CREATED' ||
          s == 'UPDATED' ||
          s == 'RESCHEDULED' ||
          s == 'REASSIGNED' ||
          s == 'CON_INSP_ONGOING' ||
          s == 'UNDER_CON_RECTIFICATION';
    }
    if (this == RfiUserRole.engineer || this == RfiUserRole.dyHodEngineer) {
      return s == 'INSPECTED_BY_CON' ||
          s == 'AE_INSP_ONGOING' ||
          s == 'UNDER_ENGG_RECTIFICATION';
    }
    return false;
  }

  bool canSubmitInspection(String status) {
    final String s = status.toUpperCase();
    if (this == RfiUserRole.contractorRep) {
      return s == 'CREATED' ||
          s == 'UPDATED' ||
          s == 'RESCHEDULED' ||
          s == 'REASSIGNED' ||
          s == 'CON_INSP_ONGOING' ||
          s == 'UNDER_CON_RECTIFICATION';
    }
    if (this == RfiUserRole.engineer || this == RfiUserRole.dyHodEngineer) {
      return s == 'INSPECTED_BY_CON' ||
          s == 'AE_INSP_ONGOING' ||
          s == 'INSPECTED_BY_AE' ||
          s == 'UNDER_ENGG_RECTIFICATION';
    }
    return false;
  }

  bool canUploadAttachments(String status) {
    final String s = status.toUpperCase();
    if (this == RfiUserRole.contractorRep) {
      return s == 'INSPECTED_BY_CON' ||
          s == 'AE_INSP_ONGOING' ||
          s == 'INSPECTED_BY_AE' ||
          s == 'UNDER_CON_RECTIFICATION' ||
          s == 'VALIDATION_PENDING' ||
          s == 'VALIDATION PENDING' ||
          s == 'INSPECTION_DONE' ||
          s == 'INSPECTION DONE';
    }
    if (this != RfiUserRole.engineer && this != RfiUserRole.dyHodEngineer) {
      return false;
    }
    return s == 'AE_INSP_ONGOING' ||
        s == 'INSPECTED_BY_AE' ||
        s == 'UNDER_ENGG_RECTIFICATION' ||
        s == 'VALIDATION_PENDING' ||
        s == 'VALIDATION PENDING' ||
        s == 'INSPECTION_DONE' ||
        s == 'INSPECTION DONE';
  }

  bool canUploadTestResults(String status) {
    final String s = status.toUpperCase();
    if (this == RfiUserRole.contractorRep) {
      return s == 'INSPECTED_BY_CON' ||
          s == 'AE_INSP_ONGOING' ||
          s == 'INSPECTED_BY_AE' ||
          s == 'UNDER_CON_RECTIFICATION' ||
          s == 'VALIDATION_PENDING' ||
          s == 'VALIDATION PENDING' ||
          s == 'INSPECTION_DONE' ||
          s == 'INSPECTION DONE';
    }
    if (this != RfiUserRole.engineer && this != RfiUserRole.dyHodEngineer) {
      return false;
    }
    return s == 'AE_INSP_ONGOING' ||
        s == 'INSPECTED_BY_AE' ||
        s == 'UNDER_ENGG_RECTIFICATION' ||
        s == 'VALIDATION_PENDING' ||
        s == 'VALIDATION PENDING' ||
        s == 'INSPECTION_DONE' ||
        s == 'INSPECTION DONE';
  }

  bool canSendForValidation(String status) {
    final String s = status.toUpperCase();
    if ((this == RfiUserRole.engineer || this == RfiUserRole.dyHodEngineer) &&
        (s == 'INSPECTED_BY_AE' || s == 'INSPECTION BY AE')) {
      return true;
    }
    return false;
  }

  bool canRejectOrClose(String status) {
    final String s = status.toUpperCase();
    if ((this == RfiUserRole.dyHod ||
            this == RfiUserRole.dyHodEngineer ||
            this == RfiUserRole.hod) &&
        (s == 'VALIDATION_PENDING' || s == 'VALIDATION PENDING')) {
      return true;
    } else if ((this == RfiUserRole.engineer ||
            this == RfiUserRole.dyHodEngineer) &&
        (s == 'INSPECTED_BY_AE' ||
            s == 'INSPECTION BY AE' ||
            s == 'VALIDATION_PENDING' ||
            s == 'VALIDATION PENDING')) {
      return true;
    }
    return false;
  }

  bool canViewRfi(String status) {
    return true;
  }

  bool canChangeExecutive(String status) {
    final String s = status.toUpperCase();
    if (this == RfiUserRole.engineer ||
        this == RfiUserRole.dyHodEngineer ||
        this == RfiUserRole.hod ||
        this == RfiUserRole.dyHod ||
        this == RfiUserRole.itAdmin) {
      return s.isEmpty ||
          s == 'CREATED' ||
          s == 'UPDATED' ||
          s == 'RESCHEDULED' ||
          s == 'REASSIGNED' ||
          s == 'CON_INSP_ONGOING' ||
          s == 'INSPECTED_BY_CON';
    }
    return false;
  }
}
