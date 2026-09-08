import 'package:flutter/material.dart';
import '../providers/app_state.dart' show ConversationMicState;

/// Barre de saisie facon chat : champ arrondi + bouton micro (push-to-talk)
/// qui bascule vers l'envoi des que le champ contient du texte tape.
///
/// Le bouton reflete directement `ConversationMicState` :
///   idle/waiting  -> pret, appui possible
///   recording     -> maintenu, ecoute en cours (glisser vers la gauche
///                    pour annuler sans envoyer)
///   processing    -> relache, transcription en cours
///   translating   -> traduction en cours
///   sending       -> transmission du tour
///   playing       -> lecture de la traduction en cours
///   error         -> une erreur est survenue
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final ConversationMicState micState;
  final int recordingSeconds;
  final String lastRecordedText;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;
  final VoidCallback onSend;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.micState,
    required this.recordingSeconds,
    this.lastRecordedText = '',
    this.onStartRecording,
    this.onStopRecording,
    this.onCancelRecording,
    required this.onSend,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const double _cancelThreshold = 72;

  double _dragDx = 0;

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

  bool get _pastCancelThreshold => _dragDx < -_cancelThreshold;

  String? _statusLabel() {
    switch (widget.micState) {
      case ConversationMicState.recording:
        if (_pastCancelThreshold) return 'Relâchez pour annuler';
        final secs = widget.recordingSeconds.toString().padLeft(2, '0');
        return 'Enregistrement 00:$secs — glissez pour annuler';
      case ConversationMicState.processing:
        return 'Transcription en cours…';
      case ConversationMicState.translating:
        return 'Traduction en cours…';
      case ConversationMicState.sending:
        return 'Envoi en cours…';
      case ConversationMicState.playing:
        return 'Lecture de la traduction…';
      case ConversationMicState.error:
        return 'Une erreur est survenue';
      case ConversationMicState.idle:
      case ConversationMicState.waiting:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isRecording = widget.micState == ConversationMicState.recording;
    final isError = widget.micState == ConversationMicState.error;
    final isBlocked = widget.micState == ConversationMicState.processing ||
        widget.micState == ConversationMicState.translating ||
        widget.micState == ConversationMicState.sending ||
        widget.micState == ConversationMicState.playing ||
        isError;
    final statusLabel = _statusLabel();
    final statusColor = isError
        ? scheme.error
        : (isRecording
            ? (_pastCancelThreshold ? scheme.error : Colors.redAccent)
            : (isBlocked ? scheme.primary : scheme.outline));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecording) ...[
                  Icon(
                    _pastCancelThreshold ? Icons.close_rounded : Icons.circle,
                    size: _pastCancelThreshold ? 14 : 9,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                ] else if (isBlocked && !isError) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: statusColor),
                  ),
                  const SizedBox(width: 6),
                ] else if (isError) ...[
                  Icon(Icons.error_outline_rounded, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  statusLabel,
                  style: TextStyle(fontWeight: FontWeight.w700, color: statusColor, fontSize: 12),
                ),
              ],
            ),
          )
        else if (!hasText && widget.onStartRecording != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Maintenez le micro pour parler',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: scheme.outline),
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
                  : (isBlocked ? Icons.mic_off_rounded : Icons.mic_rounded),
              background: hasText
                  ? scheme.primary
                  : (isBlocked
                      ? scheme.surfaceContainerHighest
                      : (isRecording
                          ? (_pastCancelThreshold ? scheme.error : Colors.redAccent)
                          : scheme.secondary)),
              foreground: hasText || isRecording
                  ? Colors.white
                  : (isBlocked ? scheme.outline : scheme.onSecondary),
              dragDx: isRecording ? _dragDx : 0,
              onTap: hasText ? widget.onSend : null,
              onPointerDown: !hasText && !isBlocked && widget.onStartRecording != null
                  ? (_) {
                      setState(() => _dragDx = 0);
                      widget.onStartRecording!();
                    }
                  : null,
              onPointerMove: isRecording
                  ? (event) {
                      // On ne suit que le glissement vers la gauche (annuler) ;
                      // vers la droite, on l'ignore (pas d'action associée).
                      final next = (_dragDx + event.delta.dx).clamp(-140.0, 0.0);
                      if (next != _dragDx) setState(() => _dragDx = next);
                    }
                  : null,
              onPointerUp: !hasText && isRecording
                  ? (_) {
                      if (_pastCancelThreshold) {
                        widget.onCancelRecording?.call();
                      } else {
                        widget.onStopRecording?.call();
                      }
                      setState(() => _dragDx = 0);
                    }
                  : null,
              onPointerCancel: !hasText && isRecording
                  ? (_) {
                      // Une annulation système (ex: appel entrant) doit jeter
                      // le message, pas l'envoyer.
                      widget.onCancelRecording?.call();
                      setState(() => _dragDx = 0);
                    }
                  : null,
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
  final double dragDx;
  final VoidCallback? onTap;
  final void Function(PointerDownEvent)? onPointerDown;
  final void Function(PointerMoveEvent)? onPointerMove;
  final void Function(PointerUpEvent)? onPointerUp;
  final void Function(PointerCancelEvent)? onPointerCancel;

  const _CircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.dragDx = 0,
    required this.onTap,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: Transform.translate(
        offset: Offset(dragDx, 0),
        child: Material(
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
        ),
      ),
    );
  }
}
