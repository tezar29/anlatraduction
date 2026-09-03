import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apparence',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  RadioGroup<ThemeMode>(
                    groupValue: state.themeMode,
                    onChanged: (m) => state.setThemeMode(m!),
                    child: const Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Automatique (système)'),
                          value: ThemeMode.system,
                        ),
                        RadioListTile<ThemeMode>(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Clair'),
                          value: ThemeMode.light,
                        ),
                        RadioListTile<ThemeMode>(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Sombre'),
                          value: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('À propos'),
              subtitle: Text(
                'Traduction Turc ↔ Français / Anglais — texte et voix.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(state.subscription?.plan.code ?? state.entitlements?.planCode ?? 'Plan FREE'),
                  subtitle: Text(
                    state.subscription != null
                        ? '${state.subscription!.status} • ${state.subscription!.plan.name}'
                        : 'Droits et quotas du compte',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  ),
                ),
                if (state.profile != null)
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(state.profile!.fullName.isEmpty
                        ? state.profile!.email
                        : state.profile!.fullName),
                    subtitle: Text(
                      '${state.profile!.email}${state.profile!.country.isNotEmpty ? ' • ${state.profile!.country}' : ''}',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Se déconnecter'),
                  onTap: state.logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
