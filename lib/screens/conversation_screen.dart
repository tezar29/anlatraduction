import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/language.dart';
import '../widgets/conversation_list_tile.dart';
import '../widgets/speaker_switcher.dart';
import '../widgets/chat_turn_bubble.dart';
import '../widgets/listening_bubble.dart';
import '../widgets/chat_composer.dart';

/// Liste des conversations — façon liste de discussions d'une appli de
/// chat (avatar, titre, langues, statut, glisser pour supprimer).
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadConversations();
    });
  }

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final state = context.read<AppState>();
    final count = _selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer $count conversations ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedIds) {
        await state.deleteConversation(id);
      }
      _clearSelection();
    }
  }

  Future<void> _create(BuildContext context) async {
    final title = TextEditingController(text: 'Conversation face-à-face');
    final second = TextEditingController(text: 'Interlocuteur');
    AppLanguage selectedLang = AppLanguage.turkish;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Titre de la conversation')),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Locuteur A (Vous)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Votre profil'),
                subtitle: Text('Automatique'),
              ),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Locuteur B (Invité)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: second,
                  decoration: const InputDecoration(
                    labelText: 'Nom du second locuteur',
                    prefixIcon: Icon(Icons.person_add_alt_1),
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<AppLanguage>(
                initialValue: selectedLang,
                decoration: const InputDecoration(labelText: 'Langue parlée'),
                items: AppLanguage.all
                    .map((lang) => DropdownMenuItem(
                        value: lang, child: Text('${lang.flagEmoji} ${lang.label}')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedLang = val);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
                onPressed: () async {
                  final state = context.read<AppState>();
                  Navigator.pop(context);
                  await state.createConversation(
                      title: title.text,
                      secondSpeaker: second.text,
                      secondSpeakerLang: selectedLang.code);

                  if (mounted && state.activeConversation != null) {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SameDeviceConversationScreen()),
                    );
                  }
                },
                child: const Text('Créer')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState state, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer cette conversation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteConversation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: scheme.surface,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} sélectionnés'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(title: const Text('Conversations')),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(context),
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Nouvelle'),
            ),
      body: RefreshIndicator(
        onRefresh: state.loadConversations,
        child: state.conversations.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.isSessionLoading) const LinearProgressIndicator(),
                  const SizedBox(height: 140),
                  Icon(Icons.forum_outlined, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('Aucune conversation', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Lancez une conversation face-à-face traduite en direct',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: scheme.outline),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final conversation = state.conversations[index];
                  final isSelected = _selectedIds.contains(conversation.id);

                  return ConversationListTile(
                    conversation: conversation,
                    isSelected: isSelected,
                    selectionMode: _isSelectionMode,
                    onLongPress: () => _toggleSelection(conversation.id),
                    onDelete: () => _confirmDelete(context, state, conversation.id),
                    onTap: () async {
                      if (_isSelectionMode) {
                        _toggleSelection(conversation.id);
                      } else {
                        await state.openConversation(conversation);
                        if (mounted) {
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SameDeviceConversationScreen()),
                          );
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

/// Fil de conversation face-à-face — présenté comme une vraie
/// conversation de chat : bulles alternées par locuteur, indicateur
/// d'écoute en direct, barre de saisie avec bascule micro/envoi.
class SameDeviceConversationScreen extends StatefulWidget {
  const SameDeviceConversationScreen({super.key});
  @override
  State<SameDeviceConversationScreen> createState() => _SameDeviceConversationScreenState();
}

class _SameDeviceConversationScreenState extends State<SameDeviceConversationScreen> {
  final controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    state.setConversationScreenActive(true);
    // Lance le micro automatiquement avec un délai plus long pour s'assurer
    // que le micro de l'écran précédent (Traduction) est complètement libéré.
    // Le délai de 2500ms est crucial pour éviter les collisions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          final state = context.read<AppState>();
          if (!state.isListening) {
            state.toggleConversationMic();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    // Désactiver micro et TTS immédiatement en sortant, et empêcher toute
    // relance automatique fantôme déclenchée par un tour encore en cours
    // de traitement en arrière-plan (voir AppState.processTextTurn).
    // setConversationScreenActive(false) coupe déjà le micro s'il tourne.
    context.read<AppState>().setConversationScreenActive(false);
    context.read<AppState>().stopAllAudio();

    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send(AppState state) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    await state.processTextTurn(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final conversation = state.activeConversation;
    final scheme = Theme.of(context).colorScheme;

    // Synchronisation du champ avec conversationInputText
    if (state.isListening && controller.text != state.conversationInputText) {
      controller.text = state.conversationInputText;
    } else if (!state.isListening && state.conversationInputText.isEmpty && controller.text.isNotEmpty) {
      // Vide le champ local si l'envoi a eu lieu
      controller.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final firstSpeakerId = state.speakers.isNotEmpty ? state.speakers.first.id : '';
    final activeSpeaker = state.speakers.isNotEmpty
        ? state.speakers.firstWhere((s) => s.active, orElse: () => state.speakers.first)
        : null;
    final activeSpeakerIsMe = activeSpeaker?.id == firstSpeakerId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.people_alt_rounded, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversation?.title ?? 'Face-à-face',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    conversation == null
                        ? ''
                        : '${conversation.sourceLanguage.toUpperCase()} ↔ ${conversation.targetLanguage.toUpperCase()} · ${_statusLabel(conversation.status)}',
                    style: TextStyle(fontSize: 11.5, color: scheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'pause') {
                  await state.pauseConversation();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
                if (action == 'resume') {
                  await state.resumeConversation();
                }
                if (action == 'end') {
                  await state.endConversation();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'pause',
                      enabled: conversation?.status != 'PAUSED' && conversation?.status != 'ENDED',
                      child: const Text('Mettre en pause'),
                    ),
                    PopupMenuItem(
                      value: 'resume',
                      enabled: conversation?.status == 'PAUSED',
                      child: const Text('Reprendre'),
                    ),
                    PopupMenuItem(
                      value: 'end',
                      enabled: conversation?.status != 'ENDED',
                      child: const Text('Terminer'),
                    ),
                  ])
        ],
      ),
      body: Column(
        children: [
          if (state.speakers.isNotEmpty && conversation != null)
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: SpeakerSwitcher(
                speakers: state.speakers,
                sourceLanguageCode: conversation.sourceLanguage,
                targetLanguageCode: conversation.targetLanguage,
                onSelected: state.activateSpeaker,
              ),
            ),
          Expanded(
            child: state.timeline.isEmpty && !state.isListening
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: scheme.outline),
                        const SizedBox(height: 10),
                        const Text('La conversation commencera ici',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    itemCount: state.timeline.length + (state.isListening ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index == state.timeline.length) {
                        // Bulle "en train de parler" en direct, en bas du fil.
                        return ListeningBubble(
                          isMe: activeSpeakerIsMe,
                          speakerName: activeSpeaker?.name ?? 'Quelqu\'un',
                          partialText: state.conversationInputText,
                          seconds: state.recordingSeconds,
                        );
                      }

                      final item = state.timeline[index];
                      final itemSpeakerId = (item['speakerId'] ?? item['participantId'] ?? '').toString();
                      final isMe =
                          itemSpeakerId == firstSpeakerId || (itemSpeakerId.isEmpty && index % 2 == 0);

                      final sourceLang = isMe ? conversation?.sourceLanguage : conversation?.targetLanguage;
                      final targetLang = isMe ? conversation?.targetLanguage : conversation?.sourceLanguage;

                      final original = (item['text'] ??
                              item['transcript'] ??
                              item['transcription']?['transcript'] ??
                              state.localOriginals[index] ??
                              '')
                          .toString();
                      final translated =
                          (item['translatedText'] ?? item['translation']?['translatedText'] ?? '')
                              .toString();
                      final speakerName =
                          (item['speakerName'] ?? item['speaker'] ?? (isMe ? 'Vous' : 'Invité')).toString();

                      if (original.isEmpty && translated.isEmpty) return const SizedBox.shrink();

                      return ChatTurnBubble(
                        isMe: isMe,
                        speakerName: isMe ? 'Vous' : speakerName,
                        originalText: original,
                        translatedText: translated,
                        onPlayOriginal:
                            original.isEmpty ? null : () => state.speakMessage(original, sourceLang ?? 'fr'),
                        onPlayTranslation: translated.isEmpty
                            ? null
                            : () => state.speakMessage(translated, targetLang ?? 'tr'),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!state.isListening && activeSpeaker != null && conversation != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_none_rounded, size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            "C'est à ${activeSpeakerIsMe ? 'vous' : activeSpeaker.name} de parler — appuyez sur le micro",
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ChatComposer(
                    controller: controller,
                    isListening: state.isListening,
                    recordingSeconds: state.recordingSeconds,
                    lastRecordedText: state.lastRecordedText,
                    onToggleMic: state.toggleConversationMic,
                    onSend: () => _send(state),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'STARTED':
        return 'En cours';
      case 'PAUSED':
        return 'En pause';
      case 'ENDED':
      case 'COMPLETED':
        return 'Terminée';
      default:
        return status;
    }
  }
}
