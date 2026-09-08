import 'package:flutter/material.dart';

/// Une bulle de chat pour un tour de parole : le texte traduit en haut,
/// suivi d'une ligne de séparation, puis le texte original en bas.
/// Le design suit le modèle : bulles avec "bec" et alignement alterné.
class ChatTurnBubble extends StatelessWidget {
  final bool isMe;
  final String speakerName;
  final String originalText;
  final String translatedText;
  final VoidCallback? onPlayOriginal;
  final VoidCallback? onPlayTranslation;

  const ChatTurnBubble({
    super.key,
    required this.isMe,
    required this.speakerName,
    required this.originalText,
    required this.translatedText,
    this.onPlayOriginal,
    this.onPlayTranslation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Définition des couleurs selon l'expéditeur
    final bubbleColor = isMe
        ? const Color(0xFF007AFF)
        : const Color(0xFFE9EDF3);
    final textColor = isMe ? Colors.white : Colors.black87;
    final secondaryTextColor = isMe ? Colors.white70 : Colors.black54;
    final dividerColor = isMe ? Colors.white30 : const Color(0xFFCBD2DC);
    final nameColor = isMe ? const Color(0xFF0066D6) : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Chaque locuteur occupe son côté du fil, comme dans une vraie
          // messagerie : nous à gauche, l'interlocuteur à droite.
          Align(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMe) _buildBeak(false, bubbleColor),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 3 : 20),
                        bottomRight: Radius.circular(isMe ? 20 : 3),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: const Color(0xFFD8DEE7)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isMe ? 0.12 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        // Traduction en premier : lecture rapide du résultat.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMe) _buildPlayBtn(onPlayTranslation, textColor),
                            Flexible(
                              child: Text(
                                translatedText.toUpperCase(),
                                textAlign: isMe ? TextAlign.left : TextAlign.right,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (!isMe) _buildPlayBtn(onPlayTranslation, textColor),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: dividerColor,
                          ),
                        ),
                        // Original sous la séparation, comme dans le brief.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMe) _buildPlayBtn(onPlayOriginal, secondaryTextColor),
                            Flexible(
                              child: Text(
                                originalText,
                                textAlign: isMe ? TextAlign.left : TextAlign.right,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            if (!isMe) _buildPlayBtn(onPlayOriginal, secondaryTextColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isMe) _buildBeak(true, bubbleColor),
              ],
            ),
          ),

          // NOM DU LOCUTEUR (En bas, discret)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 14, right: 14),
            child: Text(
              isMe ? 'Moi' : speakerName,
              textAlign: isMe ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: nameColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayBtn(VoidCallback? onTap, Color color) {
    if (onTap == null) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Icon(Icons.volume_up_rounded, size: 16, color: color.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildBeak(bool isMe, Color color) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: _BeakPainter(isMe: isMe, color: color),
      ),
    );
  }
}

class _BeakPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  _BeakPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
