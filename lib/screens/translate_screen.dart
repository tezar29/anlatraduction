import 'package:flutter/material.dart';

import '../widgets/language_bar.dart';
import '../widgets/input_card.dart';
import '../widgets/output_card.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _AnlaLogo()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
          'assets/anla_logo.jpeg',
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
