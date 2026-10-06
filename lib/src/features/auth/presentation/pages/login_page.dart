import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/app/theme/theme_mode_provider.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:swr_pmis_mobile/src/core/result/failure.dart';
import 'package:swr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/swr_logo.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _submitting = false;
  bool _autoLoggingIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapRemembered());
  }

  Future<void> _bootstrapRemembered() async {
    final AuthLocalSnapshot snap =
        await ref.read(authLocalDataSourceProvider).readSnapshot();
    if (!mounted) {
      return;
    }
    if (snap.userId != null && snap.userId!.isNotEmpty) {
      _userIdController.text = snap.userId!;
    }
    setState(() => _rememberMe = snap.rememberMe);

    final bool shouldAutoLogin = snap.rememberMe &&
        (snap.userId?.trim().isNotEmpty ?? false) &&
        (snap.password?.isNotEmpty ?? false);
    if (!shouldAutoLogin) {
      return;
    }

    setState(() => _autoLoggingIn = true);
    final Failure? failure =
        await ref.read(authControllerProvider.notifier).tryAutoLoginIfRemembered();
    if (!mounted) {
      return;
    }
    setState(() => _autoLoggingIn = false);
    if (failure == null &&
        ref.read(authControllerProvider).valueOrNull != null) {
      context.goNamed(HomePage.routeName);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    final Failure? failure =
        await ref.read(authControllerProvider.notifier).login(
              userId: _userIdController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (failure != null) {
      await GlobalDialog.error(failure.message, title: 'Login Failed');
      return;
    }
    context.goNamed(HomePage.routeName);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final double topInset = MediaQuery.paddingOf(context).top;
    final bool busy = _submitting || _autoLoggingIn;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.brandPrimary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                palette.loginBackgroundTop,
                palette.loginBackgroundBottom,
              ],
            ),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, topInset + 12, 8, 14),
                color: AppTheme.brandPrimary,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 40),
                    const Expanded(
                      child: Text(
                        AppConstants.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Appearance',
                      onPressed: () {
                        final ThemeMode next = switch (themeMode) {
                          ThemeMode.system => ThemeMode.light,
                          ThemeMode.light => ThemeMode.dark,
                          ThemeMode.dark => ThemeMode.system,
                        };
                        ref.read(themeModeProvider.notifier).setMode(next);
                      },
                      icon: Icon(
                        switch (themeMode) {
                          ThemeMode.system => Icons.brightness_auto_rounded,
                          ThemeMode.light => Icons.light_mode_rounded,
                          ThemeMode.dark => Icons.dark_mode_rounded,
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: Column(
                            children: <Widget>[
                              const SwrLogo(size: 86),
                              const SizedBox(height: 12),
                              Text(
                                AppConstants.orgName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Project Management Information System',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: palette.mutedText),
                              ),
                              const SizedBox(height: 18),
                              const _LoginCarousel(),
                              const SizedBox(height: 18),
                              _LoginCard(
                                formKey: _formKey,
                                userIdController: _userIdController,
                                passwordController: _passwordController,
                                obscure: _obscure,
                                rememberMe: _rememberMe,
                                busy: busy,
                                onToggleObscure: () =>
                                    setState(() => _obscure = !_obscure),
                                onRememberChanged: (bool? value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                onSubmit: busy ? null : _submit,
                                onForgot: () => context.pushNamed(
                                  ForgotPasswordPage.routeName,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                AppConstants.publisherLine,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: palette.mutedText),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCarousel extends StatefulWidget {
  const _LoginCarousel();

  @override
  State<_LoginCarousel> createState() => _LoginCarouselState();
}

class _LoginCarouselState extends State<_LoginCarousel> {
  static const int _virtualLoops = 10000;
  static const Duration _autoplayInterval = Duration(milliseconds: 3500);
  static const Duration _animationDuration = Duration(milliseconds: 420);

  late final PageController _controller;
  late final int _initialPage;
  Timer? _timer;
  int _index = 0;
  bool _userScrolling = false;

  int get _slideCount => AppAssets.loginSlides.length;

  @override
  void initState() {
    super.initState();
    _initialPage = _slideCount * (_virtualLoops ~/ 2);
    _controller = PageController(initialPage: _initialPage);
    _startAutoplay();
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoplayInterval, (_) => _animateToNext());
  }

  void _animateToNext() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final int current = _controller.page?.round() ?? _initialPage;
    _controller.animateToPage(
      current + 1,
      duration: _animationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userScrolling = true;
      _timer?.cancel();
    } else if (_userScrolling && notification is ScrollEndNotification) {
      _userScrolling = false;
      _startAutoplay();
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (int page) {
                  setState(() => _index = page % _slideCount);
                },
                itemCount: _slideCount * _virtualLoops,
                itemBuilder: (BuildContext context, int index) {
                  return Image.asset(
                    AppAssets.loginSlides[index % _slideCount],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_slideCount, (int i) {
            final bool selected = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.brandPrimary
                    : AppTheme.brandPrimary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.userIdController,
    required this.passwordController,
    required this.obscure,
    required this.rememberMe,
    required this.busy,
    required this.onToggleObscure,
    required this.onRememberChanged,
    required this.onSubmit,
    required this.onForgot,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final bool obscure;
  final bool rememberMe;
  final bool busy;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback? onSubmit;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    const Color fieldError = Color(0xFFFFD0D6);
    final Color fieldFill = Colors.white.withValues(alpha: 0.14);
    final Color fieldBorder = Colors.white.withValues(alpha: 0.7);
    final TextStyle fieldStyle = TextStyle(
      color: palette.loginTitle,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    OutlineInputBorder fieldOutline(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIconColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        return Colors.white70;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.error)) {
          return fieldError;
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        return Colors.white70;
      }),
      labelStyle: WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.error)) {
          return const TextStyle(
            color: fieldError,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color: palette.loginSecondaryText,
          fontWeight: FontWeight.w500,
        );
      }),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(
              color: fieldError,
              fontWeight: FontWeight.w600,
            );
          }
          if (states.contains(WidgetState.focused)) {
            return TextStyle(
              color: palette.loginTitle,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: palette.loginSecondaryText,
            fontWeight: FontWeight.w500,
          );
        },
      ),
      helperStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        height: 1.3,
      ),
      helperMaxLines: 2,
      errorStyle: const TextStyle(
        color: fieldError,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
      border: fieldOutline(fieldBorder),
      enabledBorder: fieldOutline(fieldBorder),
      focusedBorder: fieldOutline(Colors.white, width: 1.8),
      errorBorder: fieldOutline(fieldError),
      focusedErrorBorder: fieldOutline(fieldError, width: 1.8),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      decoration: BoxDecoration(
        color: palette.loginCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.brandPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: inputTheme,
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: palette.loginTitle,
            selectionColor: palette.loginTitle.withValues(alpha: 0.35),
            selectionHandleColor: palette.loginTitle,
          ),
          colorScheme: Theme.of(context).colorScheme.copyWith(error: fieldError),
        ),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'SIGN IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.loginSecondaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: userIdController,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.username],
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                cursorColor: palette.loginTitle,
                cursorErrorColor: fieldError,
                style: fieldStyle,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Case-sensitive, e.g. PMIS_IT_001',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white70,
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: obscure,
                autofillHints: const <String>[AutofillHints.password],
                cursorColor: palette.loginTitle,
                cursorErrorColor: fieldError,
                style: fieldStyle,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white70,
                  ),
                  suffixIcon: IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white70,
                    ),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter password';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => onSubmit?.call(),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: rememberMe,
                    onChanged: onRememberChanged,
                    side: const BorderSide(color: Colors.white70),
                    checkColor: AppTheme.brandPrimary,
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.transparent;
                      },
                    ),
                  ),
                  Text(
                    'Remember Me',
                    style: TextStyle(color: palette.loginTitle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.loginButton,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      palette.loginButton.withValues(alpha: 0.5),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('LOGIN'),
              ),
              TextButton(
                onPressed: onForgot,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: palette.actionLink),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
