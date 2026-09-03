import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'login_screen.dart';

class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key, this.afterSignup = false});

  final bool afterSignup;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un plan')),
      body: SafeArea(
        child: state.isSessionLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (state.availablePlans.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun plan disponible pour le moment.'),
                      ),
                    )
                  else
                    ...state.availablePlans.map((plan) {
                      final isCurrent = plan.code == (state.subscription?.plan.code ?? state.entitlements?.planCode ?? 'FREE');
                      final priceText = plan.priceAmount == 0
                          ? 'Gratuit'
                          : '${plan.priceAmount} ${plan.currency}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Actuel',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    plan.code,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      priceText,
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(plan.description.isEmpty ? 'Accès premium' : plan.description),
                              const SizedBox(height: 12),
                              _QuotaRow(label: 'Minutes audio', value: '${plan.audioMinutesLimit}'),
                              _QuotaRow(label: 'Caractères traduits', value: '${plan.translatedCharactersLimit}'),
                              _QuotaRow(label: 'TTS caractères', value: '${plan.ttsCharactersLimit}'),
                              _QuotaRow(label: 'Conversations', value: '${plan.conversationsLimit}'),
                              const SizedBox(height: 14),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isCurrent || state.isSessionLoading
                                    ? null
                                    : () async {
                                        await state.upgradePlan(plan.code);
                                        if (!context.mounted) return;
                                        if (afterSignup) {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) => const LoginScreen(),
                                            ),
                                            (route) => false,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Compte créé avec succès. Vérifiez votre email, choisissez votre forfait puis connectez-vous.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(context);
                                      },
                                child: Text(isCurrent ? 'Plan actuel' : 'Sélectionner ce plan'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (state.sessionError != null) ...[
                    const SizedBox(height: 12),
                    Text(state.sessionError!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
      ),
    );
  }
}

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
