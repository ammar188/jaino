import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/loyalty_service.dart';
import 'package:fluffychat/utils/matrix_supabase_auth.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'register_view.dart';

enum RegisterStep { form, verifyEmail }

class Register extends StatefulWidget {
  final Client client;
  final MatrixSupabaseAuthService matrixAuth;
  final LoyaltyService loyalty;

  const Register({
    required this.client,
    required this.matrixAuth,
    required this.loyalty,
    super.key,
  });

  @override
  RegisterController createState() => RegisterController();
}

class RegisterController extends State<Register> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  RegisterStep step = RegisterStep.form;

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  // UIA state — populated after step 1
  String? _uiaSession;
  String? _sid;
  late final String _clientSecret =
      DateTime.now().millisecondsSinceEpoch.toString();
  int _sendAttempt = 0;

  void toggleShowPassword() =>
      setState(() => showPassword = !loading && !showPassword);

  void toggleShowConfirmPassword() =>
      setState(() => showConfirmPassword = !loading && !showConfirmPassword);

  /// Step 1: validate form, obtain UIA session, send verification email.
  Future<void> sendVerificationEmail() async {
    final l10n = L10n.of(context);

    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    String? errorMsg;

    if (email.isEmpty || !email.contains('@')) {
      errorMsg = l10n.enterAnEmailAddress;
    } else if (username.isEmpty) {
      errorMsg = l10n.pleaseEnterYourUsername;
    } else if (!RegExp(r'^[a-z0-9._\-=/]+$').hasMatch(username)) {
      errorMsg = 'Only lowercase letters, numbers and ._-=/ are allowed';
    } else if (password.isEmpty) {
      errorMsg = l10n.pleaseEnterYourPassword;
    } else if (password.length < 8) {
      errorMsg = 'Password must be at least 8 characters';
    } else if (confirmPassword.isEmpty) {
      errorMsg = l10n.pleaseEnterYourPassword;
    } else if (password != confirmPassword) {
      errorMsg = l10n.passwordsDoNotMatch;
    }

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final client = await Matrix.of(context).getLoginClient();

      // Trigger initial register call to get the UIA session ID from the 401.
      try {
        await client.register(
          username: username,
          password: password,
          initialDeviceDisplayName: PlatformInfos.clientName,
        );
        // Server accepted registration without any auth (dummy flow won).
        // Should not happen when we want email verification, but handle gracefully.
        await widget.matrixAuth.onMatrixLogin(client);
        final supabaseUserId = widget.matrixAuth.currentUser?.id;
        if (supabaseUserId != null) {
          await widget.loyalty.onNewUserRegistered(
            supabaseUserId,
            referralCode: referralCodeController.text,
          );
        }
        if (mounted) context.go('/backup');
        return;
      } on MatrixException catch (e) {
        if (!e.requireAdditionalAuthentication) rethrow;
        _uiaSession = e.session;
      }

      // Request the email verification token.
      final tokenResponse = await client.requestTokenToRegisterEmail(
        _clientSecret,
        email,
        ++_sendAttempt,
      );
      _sid = tokenResponse.sid;

      if (mounted) setState(() => step = RegisterStep.verifyEmail);
    } on MatrixException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Resend the verification email (increments sendAttempt).
  Future<void> resendVerificationEmail() async {
    setState(() => loading = true);
    try {
      final client = await Matrix.of(context).getLoginClient();
      final tokenResponse = await client.requestTokenToRegisterEmail(
        _clientSecret,
        emailController.text.trim(),
        ++_sendAttempt,
      );
      _sid = tokenResponse.sid;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).weSentYouAnEmail)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Step 2: complete registration using the verified email credentials.
  Future<void> completeRegistration() async {
    setState(() => loading = true);
    try {
      final client = await Matrix.of(context).getLoginClient();
      await client.register(
        username: usernameController.text.trim(),
        password: passwordController.text,
        initialDeviceDisplayName: PlatformInfos.clientName,
        auth: AuthenticationThreePidCreds(
          type: AuthenticationTypes.emailIdentity,
          session: _uiaSession,
          threepidCreds: ThreepidCreds(
            sid: _sid!,
            clientSecret: _clientSecret,
          ),
        ),
      );

      await widget.matrixAuth.onMatrixLogin(client);
      final supabaseUserId = widget.matrixAuth.currentUser?.id;
      if (supabaseUserId != null) {
        await widget.loyalty.onNewUserRegistered(
          supabaseUserId,
          referralCode: referralCodeController.text,
        );
      }

      if (mounted) context.go('/backup');
    } on MatrixException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void goBackToForm() => setState(() => step = RegisterStep.form);

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RegisterView(this);
}
