import 'package:flutter/material.dart';
import '../models/backend_models.dart';
import '../models/language.dart';

/// Sélecteur "qui parle" — deux cartes (ou plus, en repli) affichant
/// chaque locuteur avec sa langue ; celle active est mise en valeur.
/// Remplace la ligne de ChoiceChip par quelque chose de plus proche
/// d'un en-tête de conversation de chat à deux participants.
class SpeakerSwitcher extends StatelessWidget {
  final List<Speaker> speakers;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final ValueChanged<Speaker> onSelected;

  const SpeakerSwitcher({
    super.key,
    required this.speakers,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.onSelected,
  });

  AppLanguage _langFor(int index) {
    final code = index == 0 ? sourceLanguageCode : targetLanguageCode;
    return AppLanguage.all.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.french,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (speakers.length != 2) {
      // Repli défensif si jamais il y a plus/moins de 2 locuteurs.
      return SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: speakers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => ChoiceChip(
            label: Text(speakers[index].name),
            selected: speakers[index].active,
            onSelected: (_) => onSelected(speakers[index]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
              child: _SpeakerCard(
                  speaker: speakers[0], language: _langFor(0), onTap: () => onSelected(speakers[0]))),
          const SizedBox(width: 8),
          Expanded(
              child: _SpeakerCard(
                  speaker: speakers[1], language: _langFor(1), onTap: () => onSelected(speakers[1]))),
        ],
      ),
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  final Speaker speaker;
  final AppLanguage language;
  final VoidCallback onTap;

  const _SpeakerCard({required this.speaker, required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = speaker.active;

    return Material(
      color: active ? scheme.primary.withValues(alpha: 0.1) : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? scheme.primary : Colors.transparent, width: 1.4),
          ),
          child: Row(
            children: [
              if (active)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.graphic_eq_rounded, size: 16, color: scheme.primary),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      speaker.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: active ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${language.flagEmoji} ${language.label}',
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
