import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/backend_models.dart';
import '../providers/app_state.dart';
import 'plan_selection_screen.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final subscription = state.subscription;
    final SubscriptionPlan plan = subscription?.plan ?? const SubscriptionPlan(
      code: 'FREE',
      name: 'Plan FREE',
      audioMinutesLimit: 0,
      translatedCharactersLimit: 0,
      ttsCharactersLimit: 0,
      conversationsLimit: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              subscription != null ? subscription.status : 'Aucun abonnement',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subscription != null
                            ? 'Statut : ${subscription.status}'
                            : 'Aucun abonnement actif',
                      ),
                      const SizedBox(height: 8),
                      if (subscription != null) ...[
                        Text('Période : ${subscription.currentPeriodStart ?? '—'} → ${subscription.currentPeriodEnd ?? '—'}'),
                        const SizedBox(height: 8),
                        Text('Essai : ${subscription.trialEnd ?? '—'}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Limites et quotas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _QuotaRow(label: 'Audio minutes', value: '${plan.audioMinutesLimit}'),
                      _QuotaRow(label: 'Caractères traduits', value: '${plan.translatedCharactersLimit}'),
                      _QuotaRow(label: 'TTS caractères', value: '${plan.ttsCharactersLimit}'),
                      _QuotaRow(label: 'Conversations', value: '${plan.conversationsLimit}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                ),
                icon: const Icon(Icons.upgrade_rounded),
                label: const Text('Voir les plans et upgrader'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.isSessionLoading ? null : () => state.renewSubscription(),
                child: const Text('Renouveler l’abonnement'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.isSessionLoading ? null : () => state.cancelSubscription(),
                child: const Text('Annuler l’abonnement'),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Factures et paiements',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (state.invoices.isEmpty && state.payments.isEmpty)
                        const Text('Aucune facture ou paiement pour le moment.')
                      else ...[
                        ...state.invoices.map((invoice) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Facture ${invoice.id.isEmpty ? '—' : invoice.id.substring(0, invoice.id.length > 8 ? 8 : invoice.id.length)}'),
                              Text('${invoice.amount} ${invoice.currency}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                        if (state.payments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...state.payments.map((payment) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Paiement ${payment.status}'),
                                Text('${payment.amount} ${payment.currency}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              if (state.sessionError != null) ...[
                const SizedBox(height: 12),
                Text(state.sessionError!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
