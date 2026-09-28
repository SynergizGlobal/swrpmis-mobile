import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    super.token = '',
    required super.userId,
    required super.userName,
    super.emailId = '',
    super.userRoleNameFk = '',
    super.userTypeFk = '',
    super.departmentFk = '',
    super.designation = '',
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys, {String fallback = ''}) {
      for (final String key in keys) {
        final dynamic value = json[key];
        if (value == null) {
          continue;
        }
        final String text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return fallback;
    }

    return AuthSessionModel(
      token: read(<String>['token', 'accessToken', 'jwt']),
      userId: read(<String>['user_id', 'userId']),
      userName: read(
        <String>['user_name', 'userName'],
        fallback: read(<String>['user_id', 'userId'], fallback: 'User'),
      ),
      emailId: read(<String>['email_id', 'emailId', 'email']),
      userRoleNameFk: read(<String>['user_role_name_fk', 'userRoleNameFk']),
      userTypeFk: read(<String>['user_type_fk', 'userTypeFk']),
      departmentFk:
          read(<String>['department_fk', 'departmentFk', 'department']),
      designation: read(<String>['designation']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'userId': userId,
      'userName': userName,
      'emailId': emailId,
      'userRoleNameFk': userRoleNameFk,
      'userTypeFk': userTypeFk,
      'departmentFk': departmentFk,
      'designation': designation,
    };
  }
}
