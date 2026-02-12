import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/MainLayout.dart';

class ConversationScreen extends StatefulWidget {
  final String partnerCode;

  const ConversationScreen({super.key, required this.partnerCode});

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

  // Charger messages locaux si existants
  Future<void> loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(widget.partnerCode);
    if (stored != null) {
      setState(() async {
        localMessages = List<String>.from(await Future.value(stored != null ? List<String>.from(List<String>.from(stored.split('|'))) : []));
      });
    }
  }

  // Sauvegarder messages localement (optionnel)
  Future<void> saveLocalMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.partnerCode, messages.join('|'));
  }

  // Envoyer message sur Firestore
  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final messageText = _controller.text.trim();

    // Ajouter message à Firestore
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.partnerCode)
        .collection('messages')
        .add({
      'sender': 'me', // ou un identifiant unique du device
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

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
              "Conversation avec ${widget.partnerCode}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Utiliser StreamBuilder pour récupérer messages en temps réel
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.partnerCode)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs.map((doc) => doc['text'].toString()).toList();

                // Sauvegarder localement pour cache (optionnel)
                saveLocalMessages(messages);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(messages[index]),
                    );
                  },
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
