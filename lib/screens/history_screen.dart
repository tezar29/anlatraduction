import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _labelFor(String code) {
    return AppLanguage.all
        .firstWhere((l) => l.code == code, orElse: () => AppLanguage.turkish)
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: state.history.isEmpty
          ? Center(
              child: Text(
                'Aucune traduction pour le moment',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = state.history[index];
                return Dismissible(
                  key: ValueKey(entry.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => state.deleteHistoryEntry(entry.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: scheme.error),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_labelFor(entry.sourceLangCode)} → ${_labelFor(entry.targetLangCode)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  entry.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: entry.isFavorite
                                      ? Colors.amber
                                      : scheme.onSurface.withValues(alpha: 0.4),
                                ),
                                onPressed: () =>
                                    state.toggleFavorite(entry.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(entry.sourceText,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const Divider(height: 20),
                          Text(
                            entry.translatedText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
