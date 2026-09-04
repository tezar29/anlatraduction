import 'package:flutter/material.dart';
import '../models/backend_models.dart';
import '../models/language.dart';

/// Une ligne de la liste des conversations, façon liste de discussions
/// d'une appli de chat : avatar, titre, langues, statut.
class ConversationListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onLongPress;

  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
    this.isSelected = false,
    this.selectionMode = false,
    this.onLongPress,
  });

  AppLanguage _langFor(String code) => AppLanguage.all.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.french,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final source = _langFor(conversation.sourceLanguage);
    final target = _langFor(conversation.targetLanguage);

    final tileColor = isSelected
        ? scheme.primary.withValues(alpha: 0.08)
        : Theme.of(context).cardColor;

    return Dismissible(
      key: ValueKey(conversation.id),
      direction: selectionMode ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: isSelected ? scheme.primary : scheme.outline,
                    ),
                  ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.people_alt_rounded, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (!selectionMode) _StatusDot(status: conversation.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${source.flagEmoji} ${source.label}  ↔  ${target.flagEmoji} ${target.label}',
                        style: TextStyle(fontSize: 12.5, color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode) Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'STARTED':
        color = Colors.green;
        label = 'En cours';
        break;
      case 'PAUSED':
        color = Colors.orange;
        label = 'En pause';
        break;
      case 'ENDED':
      case 'COMPLETED':
        color = Colors.grey;
        label = 'Terminée';
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
