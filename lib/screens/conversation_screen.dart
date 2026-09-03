import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final title = TextEditingController(text: 'Conversation face-à-face');
    final first = TextEditingController(text: 'Personne A');
    final second = TextEditingController(text: 'Personne B');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Titre')),
          TextField(
              controller: first,
              decoration: const InputDecoration(labelText: 'Premier locuteur')),
          TextField(
              controller: second,
              decoration: const InputDecoration(labelText: 'Second locuteur')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<AppState>().createConversation(
                    title: title.text,
                    firstSpeaker: first.text,
                    secondSpeaker: second.text);
              },
              child: const Text('Créer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations'), actions: [
        IconButton(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nouvelle conversation')
      ]),
      body: RefreshIndicator(
        onRefresh: state.loadConversations,
        child: state.conversations.isEmpty
            ? ListView(children: const [
                SizedBox(height: 180),
                Center(child: Text('Aucune conversation'))
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final conversation = state.conversations[index];
                  return Card(
                      child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.people_alt_outlined)),
                          title: Text(conversation.title),
                          subtitle: Text(
                              '${conversation.sourceLanguage.toUpperCase()} → ${conversation.targetLanguage.toUpperCase()} · ${conversation.status}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await state.openConversation(conversation);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SameDeviceConversationScreen(),
                                ),
                              );
                            }
                          }));
                },
              ),
      ),
    );
  }
}

class SameDeviceConversationScreen extends StatefulWidget {
  const SameDeviceConversationScreen({super.key});
  @override
  State<SameDeviceConversationScreen> createState() =>
      _SameDeviceConversationScreenState();
}

class _SameDeviceConversationScreenState
    extends State<SameDeviceConversationScreen> {
  final controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final conversation = state.activeConversation;
    return Scaffold(
      appBar:
          AppBar(title: Text(conversation?.title ?? 'Face-à-face'), actions: [
        PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'pause') state.pauseConversation();
              if (action == 'resume') state.resumeConversation();
              if (action == 'end') state.endConversation();
            },
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pause', child: Text('Mettre en pause')),
                  PopupMenuItem(value: 'resume', child: Text('Reprendre')),
                  PopupMenuItem(value: 'end', child: Text('Terminer'))
                ])
      ]),
      body: Column(children: [
        if (state.speakers.isNotEmpty)
          SizedBox(
              height: 82,
              child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.speakers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final speaker = state.speakers[index];
                    return ChoiceChip(
                        label: Text(speaker.name),
                        selected: speaker.active,
                        onSelected: (_) => state.activateSpeaker(speaker));
                  })),
        Expanded(
            child: state.timeline.isEmpty
                ? const Center(child: Text('La conversation commencera ici'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.timeline.length,
                    itemBuilder: (_, index) {
                      final item = state.timeline[index];
                      return Card(
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${item['speakerName'] ?? item['speaker'] ?? 'Locuteur'}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${item['text'] ?? item['transcript'] ?? ''}'),
                                    if (item['translatedText'] != null) ...[
                                      const Divider(),
                                      Text('${item['translatedText']}')
                                    ]
                                  ])));
                    })),
        SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                          controller: controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(state),
                          decoration: const InputDecoration(
                              hintText: 'Écrire un message'))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: () => _send(state),
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Envoyer')
                ]))),
      ]),
    );
  }

  Future<void> _send(AppState state) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    await state.processTextTurn(text);
  }
}
