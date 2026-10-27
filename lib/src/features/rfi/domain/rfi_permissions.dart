import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

class RfiPermissions {
  const RfiPermissions({
    required this.userRoleNameFk,
    this.userTypeFk = '',
    this.departmentFk = '',
    this.designation = '',
    this.userId = '',
  });

  factory RfiPermissions.fromSession(AuthSession? session) {
    return RfiPermissions(
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

  RfiUserRole get role => RfiUserRoleResolver.fromFields(
    userTypeFk: userTypeFk,
    userRoleNameFk: userRoleNameFk,
  );

  bool get isContractorRole => role == RfiUserRole.contractor;

  bool get isItAdmin => role == RfiUserRole.itAdmin;

  bool get isSuperUser => role == RfiUserRole.superUser;

  bool get canCreate => role.canCreateRfi;
}

bool rfiCanCreate({
  required String userRoleNameFk,
  String userTypeFk = '',
  String designation = '',
  String departmentFk = '',
  String userId = '',
}) {
  return RfiPermissions(
    userRoleNameFk: userRoleNameFk,
    userTypeFk: userTypeFk,
    designation: designation,
    departmentFk: departmentFk,
    userId: userId,
  ).canCreate;
}
