import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/MainLayout.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> localMessages = [];

  @override
  void initState() {
    super.initState();
    loadLocalMessages();
  }

  // Charger messages locaux si existants et enregistrer la conversation dans la liste globale
  Future<void> loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(widget.conversationId);
    if (stored != null) {
      setState(() {
        localMessages = stored.split('|');
      });
    }
    // Ajoute la conversation à la liste globale si absente
    List<String> allConvos = prefs.getStringList('conversations') ?? [];
    if (!allConvos.contains(widget.conversationId)) {
      allConvos.add(widget.conversationId);
      await prefs.setStringList('conversations', allConvos);
    }
  }

  // Sauvegarder messages localement et maintenir la liste des conversations
  Future<void> saveLocalMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.conversationId, messages.join('|'));
    // Ajoute la conversation à la liste globale si absente
    List<String> allConvos = prefs.getStringList('conversations') ?? [];
    if (!allConvos.contains(widget.conversationId)) {
      allConvos.add(widget.conversationId);
      await prefs.setStringList('conversations', allConvos);
    }
  }

  // Envoyer message (stockage local)
  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final messageText = _controller.text.trim();
    setState(() {
      localMessages.add(messageText);
    });
    await saveLocalMessages(localMessages);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            width: double.infinity,
            child: Text(
              "Conversation avec ${widget.conversationId}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: localMessages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(localMessages[index]),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Écrire un message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.red),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
