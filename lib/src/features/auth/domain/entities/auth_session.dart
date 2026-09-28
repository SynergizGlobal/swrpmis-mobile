import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    this.token = '',
    required this.userId,
    required this.userName,
    this.emailId = '',
    this.userRoleNameFk = '',
    this.userTypeFk = '',
    this.departmentFk = '',
    this.designation = '',
  });

  final String token;
  final String userId;
  final String userName;
  final String emailId;
  final String userRoleNameFk;
  final String userTypeFk;
  final String departmentFk;
  final String designation;

  @override
  List<Object?> get props => <Object?>[
        token,
        userId,
        userName,
        emailId,
        userRoleNameFk,
        userTypeFk,
        departmentFk,
        designation,
      ];
}
