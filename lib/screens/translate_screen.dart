import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/language_bar.dart';
import '../widgets/input_card.dart';
import '../widgets/output_card.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  @override
  void dispose() {
    // Couper micro et TTS : un ancien tour ne doit pas survivre à la page.
    // On attend aussi que le service voix soit complètement arrêté avant de quitter.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppState>().stopAllAudio();
      await Future.delayed(const Duration(milliseconds: 500));
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Lance le micro automatiquement à l'affichage si authentifié
    // avec un délai pour garantir l'initialisation du moteur audio.
    // Le délai de 2000ms au lieu de 1500ms laisse plus de temps pour
    // que le micro de l'écran précédent soit complètement libéré.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          final state = context.read<AppState>();
          if (state.isAuthenticated && !state.isListening) {
            state.toggleMic();
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _AnlaLogo()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: const [
            LanguageBar(),
            SizedBox(height: 16),
            InputCard(),
            SizedBox(height: 16),
            OutputCard(),
          ],
        ),
      ),
    );
  }
}

class _AnlaLogo extends StatelessWidget {
  const _AnlaLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      height: 42,
      child: ClipRect(
        child: Image.asset(
          'assets/anla.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
