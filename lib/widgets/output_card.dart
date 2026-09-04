import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class OutputCard extends StatelessWidget {
  const OutputCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    if (state.outputText.isEmpty && !state.isTranslating) {
      return _EmptyState(scheme: scheme);
    }

    return Card(
      color: scheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.targetLang.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (state.isTranslating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              )
            else
              SelectableText(
                state.outputText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (!state.isTranslating && state.lastRecordedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: 8),
              Text(
                state.lastRecordedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            if (!state.isTranslating && state.outputText.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Écouter',
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: state.speakOutput,
                  ),
                  IconButton(
                    tooltip: 'Copier',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: state.outputText),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Texte copié'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.translate_rounded,
            size: 44,
            color: scheme.primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'La traduction apparaîtra ici',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
