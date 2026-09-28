import 'package:swr_pmis_mobile/src/core/result/result.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required String userId,
    required String password,
  }) {
    return _repository.login(userId: userId, password: password);
  }
}
