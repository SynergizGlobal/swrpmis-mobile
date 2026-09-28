import 'package:swr_pmis_mobile/src/core/result/result.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<Result<AuthSession>> login({
    required String userId,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<void>> sendForgotPasswordOtp({required String emailId});

  Future<Result<void>> verifyForgotPasswordOtp({
    required String emailId,
    required String otp,
  });

  Future<Result<void>> resetForgotPassword({
    required String emailId,
    required String newPassword,
    required String confirmPassword,
  });
}
