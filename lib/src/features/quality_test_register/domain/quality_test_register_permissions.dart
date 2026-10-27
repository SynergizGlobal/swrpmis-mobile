import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

class QualityTestRegisterPermissions {
  const QualityTestRegisterPermissions({
    required this.userRoleNameFk,
    this.userTypeFk = '',
    this.departmentFk = '',
    this.designation = '',
  });

  factory QualityTestRegisterPermissions.fromSession(AuthSession? session) {
    return QualityTestRegisterPermissions(
      userRoleNameFk: session?.userRoleNameFk ?? '',
      userTypeFk: session?.userTypeFk ?? '',
      departmentFk: session?.departmentFk ?? '',
      designation: session?.designation ?? '',
    );
  }

  final String userRoleNameFk;
  final String userTypeFk;
  final String departmentFk;
  final String designation;

  bool get isContractorRole =>
      qualityTestRegisterIsContractorRole(userRoleNameFk);

  bool get canCreate => !isContractorRole;
}

bool qualityTestRegisterIsContractorRole(String userRoleNameFk) {
  return userRoleNameFk.trim().toLowerCase() == 'contractor';
}

bool qualityTestRegisterCanCreate({
  required String userRoleNameFk,
  String userTypeFk = '',
  String designation = '',
  String departmentFk = '',
}) {
  return QualityTestRegisterPermissions(
    userRoleNameFk: userRoleNameFk,
    userTypeFk: userTypeFk,
    designation: designation,
    departmentFk: departmentFk,
  ).canCreate;
}
