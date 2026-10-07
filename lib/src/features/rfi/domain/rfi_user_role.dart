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
}
