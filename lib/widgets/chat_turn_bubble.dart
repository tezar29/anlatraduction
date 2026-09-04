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
        ? const Color(0xFF007AFF) // Bleu vif pour le locuteur courant
        : const Color(0xFFF0F2F5); // Gris clair distinct pour l'interlocuteur
    final textColor = isMe ? Colors.white : Colors.black87;
    final secondaryTextColor = isMe ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle de message avec son "bec"
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
              if (!isMe) _buildBeak(false, bubbleColor),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isMe ? 22 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // 1. TEXTE TRADUIT (En haut)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMe) _buildPlayBtn(onPlayTranslation, textColor),
                          Flexible(
                            child: Text(
                              translatedText.toUpperCase(),
                              textAlign: isMe ? TextAlign.right : TextAlign.left,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (!isMe) _buildPlayBtn(onPlayTranslation, textColor),
                        ],
                      ),
                      
                      // 2. LIGNE DE SÉPARATION (Entre les deux textes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(
                          height: 1, 
                          thickness: 0.8, 
                          color: isMe ? Colors.white30 : Colors.black12,
                        ),
                      ),

                      // 3. TEXTE ORIGINAL (En bas)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMe) _buildPlayBtn(onPlayOriginal, secondaryTextColor),
                          Flexible(
                            child: Text(
                              originalText,
                              textAlign: isMe ? TextAlign.right : TextAlign.left,
                              style: TextStyle(
                                fontSize: 13,
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
              if (isMe) _buildBeak(true, bubbleColor),
              ],
            ),
          ),
          
          // NOM DU LOCUTEUR (En bas, discret)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 14, right: 14),
            child: Text(
              isMe ? 'Moi' : speakerName,
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: scheme.outline,
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
