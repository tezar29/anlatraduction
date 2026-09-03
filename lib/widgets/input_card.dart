import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class InputCard extends StatefulWidget {
  const InputCard({super.key});

  @override
  State<InputCard> createState() => _InputCardState();
}

class _InputCardState extends State<InputCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<AppState>().inputText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    // Synchronise le champ si le texte a été rempli par la voix.
    if (_controller.text != state.inputText) {
      _controller.value = _controller.value.copyWith(
        text: state.inputText,
        selection: TextSelection.collapsed(offset: state.inputText.length),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  state.sourceLang.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (state.inputText.isNotEmpty)
                  IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: state.clear,
                  ),
              ],
            ),
            TextField(
              controller: _controller,
              onChanged: state.setInputText,
              minLines: 2,
              maxLines: 6,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Écrivez ou dictez un texte à traduire…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MicButton(isListening: state.isListening),
                FilledButton.icon(
                  onPressed: state.isTranslating || state.inputText.isEmpty
                      ? null
                      : state.translate,
                  icon: state.isTranslating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text('Traduire'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.isListening});
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: isListening
          ? scheme.error.withValues(alpha: 0.12)
          : scheme.primary.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: state.toggleMic,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: isListening ? scheme.error : scheme.primary,
          ),
        ),
      ),
    );
  }
}
