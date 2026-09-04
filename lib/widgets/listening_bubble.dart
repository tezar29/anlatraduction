import 'package:flutter/material.dart';

/// Bulle affichée pendant l'enregistrement, à la place de la bannière
/// rouge précédente — comme l'indicateur "en train d'écrire" d'un chat,
/// avec le texte partiel reconnu en direct et un chrono.
class ListeningBubble extends StatelessWidget {
  final bool isMe;
  final String speakerName;
  final String partialText;
  final int seconds;

  const ListeningBubble({
    super.key,
    required this.isMe,
    required this.speakerName,
    required this.partialText,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: scheme.secondary,
              child: const Icon(Icons.mic_rounded, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0, bottom: 3),
                  child: Text('$speakerName écoute…',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: scheme.outline)),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? scheme.primary.withValues(alpha: 0.85) : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: isMe ? Colors.white : Colors.redAccent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          partialText.isEmpty ? 'Je vous écoute…' : partialText,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: partialText.isEmpty ? FontStyle.italic : FontStyle.normal,
                            color: isMe ? Colors.white : scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$minutes:$secs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: (isMe ? Colors.white : scheme.onSurface).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 15,
              backgroundColor: scheme.primary,
              child: const Icon(Icons.mic_rounded, size: 15, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
