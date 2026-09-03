import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final primaryLanguage = TextEditingController(text: 'fr');
  final country = TextEditingController(text: 'FR');
  final timezone = TextEditingController(text: 'Europe/Paris');
  bool _passwordVisible = false;

  Future<void> _submit() async {
    final state = context.read<AppState>();
    await state.register(
      email: email.text,
      password: password.text,
      firstName: firstName.text,
      lastName: lastName.text,
      primaryLanguage: primaryLanguage.text,
      country: country.text,
      timezone: timezone.text,
    );

    if (!mounted) return;
    if (state.sessionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.sessionError!)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(initialEmail: email.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
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
                        'Créez votre compte Anla',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les informations ci-dessous correspondent au payload attendu par le backend.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: firstName,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lastName,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: primaryLanguage,
                        decoration: const InputDecoration(labelText: 'Langue principale'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: country,
                        decoration: const InputDecoration(labelText: 'Pays'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: timezone,
                        decoration: const InputDecoration(labelText: 'Timezone'),
                      ),
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
                        onPressed: state.isSessionLoading ? null : _submit,
                        child: state.isSessionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Créer mon compte'),
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
