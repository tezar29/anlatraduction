import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final newPassword = TextEditingController();
  bool isResetStep = false;
  bool _passwordVisible = false;

  Future<void> _requestReset() async {
    final state = context.read<AppState>();
    await state.requestPasswordReset(email.text);
    if (!mounted) return;
    if (state.sessionError == null) {
      setState(() => isResetStep = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code de réinitialisation envoyé.')),
      );
    }
  }

  Future<void> _resetPassword() async {
    final state = context.read<AppState>();
    await state.resetPassword(
      email: email.text,
      code: code.text,
      newPassword: newPassword.text,
    );
    if (!mounted) return;
    if (state.sessionError == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Réinitialiser votre mot de passe',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      if (isResetStep) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: code,
                          decoration: const InputDecoration(labelText: 'Code reçu'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPassword,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                      ],
                      if (state.sessionError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.sessionError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: state.isSessionLoading
                            ? null
                            : (isResetStep ? _resetPassword : _requestReset),
                        child: state.isSessionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isResetStep ? 'Valider le mot de passe' : 'Envoyer le code'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
