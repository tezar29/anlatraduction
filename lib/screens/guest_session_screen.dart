import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'translate_screen.dart';

class GuestSessionScreen extends StatefulWidget {
  const GuestSessionScreen({super.key});

  @override
  State<GuestSessionScreen> createState() => _GuestSessionScreenState();
}

class _GuestSessionScreenState extends State<GuestSessionScreen> {
  final displayName = TextEditingController(text: 'Invité');
  final deviceId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, int> _quotaFromUsage(dynamic raw) {
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final usage = data['usage'] is Map
        ? Map<String, dynamic>.from(data['usage'])
        : data;

    final used = _safeInt(
      usage['used'] ??
          usage['usedToday'] ??
          usage['count'] ??
          data['used'] ??
          data['usedToday'] ??
          data['count'] ??
          0,
    );
    final limit = _safeInt(
      usage['limit'] ??
          usage['quota'] ??
          usage['dailyLimit'] ??
          data['limit'] ??
          data['quota'] ??
          data['dailyLimit'] ??
          10,
    );

    return {'used': used, 'limit': limit};
  }

  Future<void> _continueAsGuest() async {
    final state = context.read<AppState>();
    await state.createGuestSession(
      deviceId: deviceId,
      displayName: displayName.text.trim().isEmpty ? 'Invité' : displayName.text.trim(),
      sourceLanguage: state.sourceLang.code,
      targetLanguage: state.targetLang.code,
    );

    if (!mounted) return;
    if (state.sessionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.sessionError!)),
      );
      return;
    }

    await state.loadGuestDailyUsage();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TranslateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final quota = _quotaFromUsage(state.guestDailyUsage);
    final used = quota['used'] ?? 0;
    final limit = quota['limit'] ?? 0;
    final usageLabel = '$used / $limit';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session invitée'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Icon(
                    Icons.person_2_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Commencer sans compte',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez une session temporaire pour tester l’application et suivre votre quota quotidien.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: displayName,
                    decoration: const InputDecoration(
                      labelText: 'Nom affiché',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quota quotidien',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: limit > 0
                                      ? (used / limit).clamp(0.0, 1.0)
                                      : 0,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                usageLabel,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.guestSession == null
                                ? 'Aucune session active pour le moment.'
                                : 'Session active · ${state.guestSession!.status}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.guestSession != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de la session',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('ID: ${state.guestSession!.id.isEmpty ? 'non disponible' : state.guestSession!.id}'),
                          Text('Appareil: ${state.guestSession!.deviceId.isEmpty ? deviceId : state.guestSession!.deviceId}'),
                          Text('Langue source: ${state.guestSession!.sourceLanguage}'),
                          Text('Langue cible: ${state.guestSession!.targetLanguage}'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: state.isSessionLoading ? null : _continueAsGuest,
                    child: state.isSessionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer la session invitée'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour à la connexion'),
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
