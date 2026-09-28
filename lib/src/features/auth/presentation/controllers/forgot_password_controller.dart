import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/result/failure.dart';
import 'package:swr_pmis_mobile/src/core/result/result.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/repositories/auth_repository.dart';

enum ForgotPasswordStep { email, otp, reset }

class ForgotPasswordState {
  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.isLoading = false,
    this.email = '',
  });

  final ForgotPasswordStep step;
  final bool isLoading;
  final String email;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    bool? isLoading,
    String? email,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
    );
  }
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._repository)
      : super(const ForgotPasswordState());

  final AuthRepository _repository;

  void seedEmail(String email) {
    final String trimmed = email.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(email: trimmed);
  }

  void goBack() {
    switch (state.step) {
      case ForgotPasswordStep.email:
        return;
      case ForgotPasswordStep.otp:
        state = state.copyWith(step: ForgotPasswordStep.email, isLoading: false);
        return;
      case ForgotPasswordStep.reset:
        state = state.copyWith(step: ForgotPasswordStep.otp, isLoading: false);
        return;
    }
  }

  Future<Failure?> sendOtp(String emailId) async {
    state = state.copyWith(isLoading: true, email: emailId);
    final Result<void> result = await _repository.sendForgotPasswordOtp(
      emailId: emailId,
    );
    return result.fold<Future<Failure?>>((Failure failure) async {
      state = state.copyWith(isLoading: false);
      return failure;
    }, (_) async {
      state = state.copyWith(isLoading: false, step: ForgotPasswordStep.otp);
      return null;
    });
  }

  Future<Failure?> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true);
    final Result<void> result = await _repository.verifyForgotPasswordOtp(
      emailId: state.email,
      otp: otp,
    );
    return result.fold<Future<Failure?>>((Failure failure) async {
      state = state.copyWith(isLoading: false);
      return failure;
    }, (_) async {
      state = state.copyWith(isLoading: false, step: ForgotPasswordStep.reset);
      return null;
    });
  }

  Future<Failure?> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    final Result<void> result = await _repository.resetForgotPassword(
      emailId: state.email,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return result.fold<Future<Failure?>>((Failure failure) async {
      state = state.copyWith(isLoading: false);
      return failure;
    }, (_) async {
      state = state.copyWith(isLoading: false);
      return null;
    });
  }
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref.watch(authRepositoryProvider));
});
