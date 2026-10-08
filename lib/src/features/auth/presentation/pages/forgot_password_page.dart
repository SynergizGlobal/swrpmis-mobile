import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/result/failure.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  static const String routeName = 'forgot-password';
  static const String routePath = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seeded) {
        return;
      }
      _seeded = true;
      final String email =
          ref.read(authControllerProvider).valueOrNull?.emailId.trim() ?? '';
      if (email.isEmpty) {
        return;
      }
      _emailController.text = email;
      ref.read(forgotPasswordControllerProvider.notifier).seedEmail(email);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showError(Failure failure) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: failure.code ?? 'Request Failed',
      message: failure.message,
    );
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .sendOtp(_emailController.text.trim());
    if (!mounted || failure == null) {
      return;
    }
    await _showError(failure);
  }

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .verifyOtp(_otpController.text.trim());
    if (!mounted || failure == null) {
      return;
    }
    await _showError(failure);
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Failure? failure = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .resetPassword(
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted) {
      return;
    }
    if (failure != null) {
      await _showError(failure);
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: 'Password reset',
      message: 'Password updated. Please sign in with your new password.',
    );
    if (mounted) {
      context.goNamed(LoginPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordState state = ref.watch(
      forgotPasswordControllerProvider,
    );
    final String title = switch (state.step) {
      ForgotPasswordStep.email => 'Forgot password',
      ForgotPasswordStep.otp => 'Verify OTP',
      ForgotPasswordStep.reset => 'Set new password',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (state.step == ForgotPasswordStep.email) {
              context.pop();
              return;
            }
            ref.read(forgotPasswordControllerProvider.notifier).goBack();
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(switch (state.step) {
              ForgotPasswordStep.email =>
                'Enter the email linked to your SWR PMIS account. We will send a one-time code.',
              ForgotPasswordStep.otp => 'Enter the OTP sent to ${state.email}.',
              ForgotPasswordStep.reset =>
                'Choose a new password for ${state.email}.',
            }),
            const SizedBox(height: 20),
            if (state.step == ForgotPasswordStep.email)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter email';
                  }
                  return null;
                },
              ),
            if (state.step == ForgotPasswordStep.otp)
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'OTP'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter OTP';
                  }
                  return null;
                },
              ),
            if (state.step == ForgotPasswordStep.reset) ...<Widget>[
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (String? value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isLoading
                  ? null
                  : switch (state.step) {
                      ForgotPasswordStep.email => _sendOtp,
                      ForgotPasswordStep.otp => _verifyOtp,
                      ForgotPasswordStep.reset => _reset,
                    },
              child: state.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(switch (state.step) {
                      ForgotPasswordStep.email => 'Send OTP',
                      ForgotPasswordStep.otp => 'Verify',
                      ForgotPasswordStep.reset => 'Update password',
                    }),
            ),
          ],
        ),
      ),
    );
  }
}
