import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'plan_selection_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final email = TextEditingController(text: widget.initialEmail);
  final code = TextEditingController();
  bool showCodeField = false;

  Future<void> _resend() async {
    final state = context.read<AppState>();
    await state.resendVerification(email.text);
    if (!mounted) return;
    if (state.sessionError == null) {
      setState(() => showCodeField = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code de vérification envoyé.')),
      );
    }
  }

  Future<void> _verify() async {
    final state = context.read<AppState>();
    await state.verifyEmail(email: email.text, code: code.text);
    if (!mounted) return;
    if (state.sessionError == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PlanSelectionScreen(afterSignup: true),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse email vérifiée. Choisissez votre forfait.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Valider votre adresse e-mail',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  if (showCodeField)
                    TextField(
                      controller: code,
                      decoration: const InputDecoration(labelText: 'Code de vérification'),
                    ),
                  if (state.sessionError != null) ...[
                    const SizedBox(height: 12),
                    Text(state.sessionError!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: state.isSessionLoading ? null : (showCodeField ? _verify : _resend),
                    child: state.isSessionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(showCodeField ? 'Vérifier mon email' : 'Envoyer le code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
