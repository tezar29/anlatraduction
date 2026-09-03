import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final fullName = TextEditingController();
  final preferredLanguage = TextEditingController(text: 'fr');
  final country = TextEditingController();
  final timezone = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    fullName.text = profile.fullName;
    preferredLanguage.text = profile.preferredLanguage;
    country.text = profile.country;
    timezone.text = profile.timezone;
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.updateProfile(
      fullName: fullName.text,
      preferredLanguage: preferredLanguage.text,
      country: country.text,
      timezone: timezone.text,
    );

    if (!mounted) return;
    if (state.sessionError == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil utilisateur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (profile != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName.isEmpty ? profile.email : profile.fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(profile.email),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              profile.emailVerified ? 'Email vérifié' : 'Email non vérifié',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: fullName,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: preferredLanguage,
                  decoration: const InputDecoration(labelText: 'Langue préférée'),
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
                  Text(state.sessionError!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: state.isSessionLoading ? null : _save,
                  child: state.isSessionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
