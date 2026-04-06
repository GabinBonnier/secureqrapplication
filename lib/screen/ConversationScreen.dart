import 'package:flutter/material.dart';
import 'dart:async';
import '../layout/MainLayout.dart';
import '../services/ElementService.dart';
import '../crypto/relationship_key_storage.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  const ConversationScreen({super.key, required this.conversationId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  String selectedType = 'MESSAGE';
  String? selectedEmoji;
  Color? selectedColor;

  final List<String> emojiList = ['😀', '🎉', '👍', '❤️', '🔥', '😎'];
  final List<Color> colorList = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool keysReady = false;
  String? errorMessage;
  String? keyStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    checkKeysReady();
    fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) { fetchMessages(); checkKeysReady(); }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> checkKeysReady() async {
    try {
      final partnerKey = await RelationshipKeyStorage().readPartnerPublicKey(widget.conversationId);
      if (mounted) setState(() {
        keysReady = partnerKey != null;
        keyStatus = keysReady ? 'Clés RSA prêtes ✅' : 'Attente des clés du partenaire... ⏳';
      });
    } catch (e) {
      if (mounted) setState(() => keyStatus = 'Erreur clés: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> fetchMessages() async {
    try {
      final result = await ElementService.fetchElements(widget.conversationId);
      if (mounted) setState(() { messages = result; errorMessage = null; });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Erreur récupération : $e');
    }
  }

  Future<void> sendMessage() async {
    String value = '';
    if (selectedType == 'MESSAGE') {
      value = _controller.text.trim();
      if (value.isEmpty) return;
    } else if (selectedType == 'ICON') {
      if (selectedEmoji == null) return;
      value = selectedEmoji!;
    } else if (selectedType == 'COLOR') {
      if (selectedColor == null) return;
      value = '0x${selectedColor!.value.toRadixString(16).toUpperCase()}';
    }

    setState(() => isLoading = true);
    try {
      final ok = await ElementService.sendElement(
          relationCode: widget.conversationId, type: selectedType, value: value);
      if (ok) {
        _controller.clear();
        setState(() { selectedEmoji = null; selectedColor = null; });
        await fetchMessages();
      } else {
        setState(() => errorMessage = "Erreur lors de l'envoi.");
      }
    } catch (e) {
      setState(() => errorMessage = 'Erreur envoi : $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Conversation avec ${widget.conversationId}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: keysReady ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(children: [
                  Icon(keysReady ? Icons.security : Icons.hourglass_empty,
                      size: 16, color: keysReady ? Colors.green : Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(child: Text(keyStatus ?? 'Vérification...',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: keysReady ? Colors.green[800] : Colors.orange[800]))),
                ]),
              ),
            ]),
          ),

          // Bandeau erreur
          if (errorMessage != null)
            Container(
              color: Colors.red[50],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
                IconButton(icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => errorMessage = null)),
              ]),
            ),

          // Liste des messages
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMessages,
              child: messages.isEmpty
                  ? const Center(child: Text('Aucun message.'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isSent = msg['isSent'] == true;
                        return Align(
                          alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isSent ? Colors.red[400] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msg['value'] ?? '',
                                style: TextStyle(color: isSent ? Colors.white : Colors.black87)),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Sélecteur de type
              Row(children: [
                const Text('Type :', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'MESSAGE', child: Text('💬 Message')),
                    DropdownMenuItem(value: 'ICON', child: Text('😀 Emoji')),
                    DropdownMenuItem(value: 'COLOR', child: Text('🎨 Couleur')),
                  ],
                  onChanged: (val) => setState(() {
                    selectedType = val!;
                    selectedEmoji = null;
                    selectedColor = null;
                  }),
                ),
              ]),

              if (selectedType == 'MESSAGE')
                Row(children: [
                  Expanded(child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Écrire un message...", border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: (isLoading || !keysReady) ? Colors.grey : Colors.red),
                    onPressed: (isLoading || !keysReady) ? null : sendMessage,
                  ),
                ]),

              if (selectedType == 'ICON')
                Row(children: [
                  Expanded(child: Wrap(spacing: 8, children: emojiList.map((e) => GestureDetector(
                    onTap: () => setState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? Colors.red[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: selectedEmoji == e ? Border.all(color: Colors.red, width: 2) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList())),
                  IconButton(
                    icon: Icon(Icons.send, color: (isLoading || !keysReady || selectedEmoji == null) ? Colors.grey : Colors.red),
                    onPressed: (isLoading || !keysReady || selectedEmoji == null) ? null : sendMessage,
                  ),
                ]),

              if (selectedType == 'COLOR')
                Row(children: [
                  Expanded(child: Wrap(spacing: 8, children: colorList.map((c) => GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c, shape: BoxShape.circle,
                        border: selectedColor == c
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                  )).toList())),
                  IconButton(
                    icon: Icon(Icons.send, color: (isLoading || !keysReady || selectedColor == null) ? Colors.grey : Colors.red),
                    onPressed: (isLoading || !keysReady || selectedColor == null) ? null : sendMessage,
                  ),
                ]),
            ]),
          ),
        ],
      ),
    );
  }
}