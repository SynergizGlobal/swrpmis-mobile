import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

class MaterialReceiptsPermissions {
  const MaterialReceiptsPermissions({
    required this.userRoleNameFk,
    this.userTypeFk = '',
    this.departmentFk = '',
    this.designation = '',
    this.userId = '',
  });

  factory MaterialReceiptsPermissions.fromSession(AuthSession? session) {
    return MaterialReceiptsPermissions(
      userRoleNameFk: session?.userRoleNameFk ?? '',
      userTypeFk: session?.userTypeFk ?? '',
      departmentFk: session?.departmentFk ?? '',
      designation: session?.designation ?? '',
      userId: session?.userId ?? '',
    );
  }

  final String userRoleNameFk;
  final String userTypeFk;
  final String departmentFk;
  final String designation;
  final String userId;

  bool get isContractorRole =>
      materialReceiptsIsRole(userRoleNameFk, 'Contractor');

  bool get isItAdmin => materialReceiptsIsRole(userRoleNameFk, 'IT Admin');

  bool get isFullAccess => isItAdmin;

  bool get canCreate => isContractorRole || isItAdmin;
}

bool materialReceiptsIsRole(String userRoleNameFk, String role) {
  return userRoleNameFk.trim().toLowerCase() == role.trim().toLowerCase();
}

bool materialReceiptsCanCreate({
  required String userRoleNameFk,
  String userTypeFk = '',
  String designation = '',
  String departmentFk = '',
  String userId = '',
}) {
  return MaterialReceiptsPermissions(
    userRoleNameFk: userRoleNameFk,
    userTypeFk: userTypeFk,
    designation: designation,
    departmentFk: departmentFk,
    userId: userId,
  ).canCreate;
}
