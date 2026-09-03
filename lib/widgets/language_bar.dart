import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/language.dart';
import '../providers/app_state.dart';

/// Barre du haut affichant la langue source, un bouton d'inversion,
/// et un sélecteur pour la langue cible (français / anglais).
class LanguageBar extends StatelessWidget {
  const LanguageBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _LanguagePill(
              language: state.sourceLang,
              alignRight: false,
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: state.swapLanguages,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: _TargetLanguagePicker(
                current: state.targetLang,
                onChanged: state.setTargetLang,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.language, required this.alignRight});
  final AppLanguage language;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          Text(language.flagEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            language.label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TargetLanguagePicker extends StatelessWidget {
  const _TargetLanguagePicker({required this.current, required this.onChanged});
  final AppLanguage current;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return PopupMenuButton<AppLanguage>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => AppLanguage.targets
          .map(
            (lang) {
              final recommended = state.recommendedLanguagePacks.any(
                (pack) => pack.code.toLowerCase() == lang.code.toLowerCase(),
              );
              final installed = state.availableLanguagePacks.any(
                    (pack) =>
                        pack.code.toLowerCase() == lang.code.toLowerCase() &&
                        pack.offlineAvailable,
                  ) ||
                  state.installedLanguagePacks.any(
                    (install) =>
                        install.languageCode.toLowerCase() == lang.code.toLowerCase(),
                  );

              return PopupMenuItem(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flagEmoji),
                    const SizedBox(width: 8),
                    Text(lang.label),
                    if (recommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Recommandé',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                    if (installed) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.download_done_rounded, size: 16),
                    ],
                  ],
                ),
              );
            },
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(current.flagEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      current.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (current.isPackInstalled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Installé',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          ),
          if (current.isPackInstalled)
            IconButton(
              onPressed: () async {
                await state.uninstallLanguagePack(current);
              },
              tooltip: 'Désinstaller le pack',
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            IconButton(
              onPressed: () async {
                await state.installLanguagePack(current);
              },
              tooltip: 'Installer le pack',
              icon: const Icon(Icons.download_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
