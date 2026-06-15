import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:flutter/material.dart';

import 'register.dart';

class RegisterView extends StatelessWidget {
  final RegisterController controller;

  const RegisterView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return switch (controller.step) {
      RegisterStep.form => _FormView(controller),
      RegisterStep.verifyEmail => _VerifyEmailView(controller),
    };
  }
}

class _FormView extends StatelessWidget {
  final RegisterController controller;
  const _FormView(this.controller);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);

    final homeserver = controller.widget.client.homeserver
        ?.toString()
        .replaceFirst('https://', '');

    return LoginScaffold(
      appBar: AppBar(
        leading:
            controller.loading ? null : const Center(child: BackButton()),
        automaticallyImplyLeading: !controller.loading,
        titleSpacing: !controller.loading ? 0 : null,
        title: Text(l10n.createNewAccount),
      ),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            if (homeserver != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'on $homeserver',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                readOnly: controller.loading,
                autocorrect: false,
                autofocus: true,
                controller: controller.emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints:
                    controller.loading ? null : [AutofillHints.email],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: controller.emailError,
                  errorStyle: const TextStyle(color: Colors.orange),
                  hintText: 'you@example.com',
                  labelText: l10n.addEmail,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                readOnly: controller.loading,
                autocorrect: false,
                controller: controller.usernameController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                autofillHints:
                    controller.loading ? null : [AutofillHints.newUsername],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_box_outlined),
                  errorText: controller.usernameError,
                  errorStyle: const TextStyle(color: Colors.orange),
                  hintText: 'username',
                  labelText: l10n.username,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                readOnly: controller.loading,
                autocorrect: false,
                controller: controller.passwordController,
                textInputAction: TextInputAction.next,
                obscureText: !controller.showPassword,
                autofillHints:
                    controller.loading ? null : [AutofillHints.newPassword],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: controller.passwordError,
                  errorStyle: const TextStyle(color: Colors.orange),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleShowPassword,
                    icon: Icon(
                      controller.showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  hintText: '••••••••',
                  labelText: l10n.password,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                readOnly: controller.loading,
                autocorrect: false,
                controller: controller.confirmPasswordController,
                textInputAction: TextInputAction.go,
                obscureText: !controller.showConfirmPassword,
                onSubmitted: (_) => controller.sendVerificationEmail(),
                autofillHints:
                    controller.loading ? null : [AutofillHints.newPassword],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: controller.confirmPasswordError,
                  errorStyle: const TextStyle(color: Colors.orange),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleShowConfirmPassword,
                    icon: Icon(
                      controller.showConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  hintText: '••••••••',
                  labelText: l10n.repeatPassword,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: controller.loading
                    ? null
                    : controller.sendVerificationEmail,
                child: controller.loading
                    ? const LinearProgressIndicator()
                    : Text(l10n.continueText),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VerifyEmailView extends StatelessWidget {
  final RegisterController controller;
  const _VerifyEmailView(this.controller);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final email = controller.emailController.text.trim();

    return LoginScaffold(
      appBar: AppBar(
        leading: controller.loading
            ? null
            : Center(
                child: BackButton(onPressed: controller.goBackToForm),
              ),
        automaticallyImplyLeading: !controller.loading,
        titleSpacing: !controller.loading ? 0 : null,
        title: Text(l10n.weSentYouAnEmail),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.weSentYouAnEmail,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              email,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pleaseClickOnLink,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed:
                  controller.loading ? null : controller.completeRegistration,
              child: controller.loading
                  ? const LinearProgressIndicator()
                  : Text(l10n.iHaveClickedOnLink),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: controller.loading
                  ? null
                  : controller.resendVerificationEmail,
              child: const Text('Resend email'),
            ),
          ],
        ),
      ),
    );
  }
}
