import 'package:flutter/material.dart';

/// Barre de saisie façon chat : champ arrondi + bouton qui bascule
/// entre micro (quand le champ est vide) et envoi (dès qu'il y a du texte).
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isListening;
  final int recordingSeconds;
  final String lastRecordedText;
  final VoidCallback onToggleMic;
  final VoidCallback onSend;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.isListening,
    required this.recordingSeconds,
    this.lastRecordedText = '',
    required this.onToggleMic,
    required this.onSend,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isListening)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 9, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  'Enregistrement 00:${widget.recordingSeconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
          )
        else if (widget.lastRecordedText.isNotEmpty && !hasText)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Dernier envoi : ${widget.lastRecordedText}',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: scheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => widget.onSend(),
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message…',
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              icon: hasText
                  ? Icons.send_rounded
                  : (widget.isListening ? Icons.stop_rounded : Icons.mic_rounded),
              background: hasText
                  ? scheme.primary
                  : (widget.isListening ? Colors.redAccent : scheme.secondary),
              foreground: hasText ? Colors.white : (widget.isListening ? Colors.white : scheme.onSecondary),
              onTap: hasText ? widget.onSend : widget.onToggleMic,
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}
