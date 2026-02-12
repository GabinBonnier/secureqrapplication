import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/MainLayout.dart';
import 'dart:convert'; // Pour convertir List<String> en JSON

class ConversationScreen extends StatefulWidget {
  final String partnerCode;

  const ConversationScreen({super.key, required this.partnerCode});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  // Charger les messages depuis le stockage local
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(widget.partnerCode);
    if (stored != null) {
      setState(() {
        messages = List<String>.from(jsonDecode(stored));
      });
    }
  }

  // Sauvegarder les messages dans le stockage local
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.partnerCode, jsonEncode(messages));
  }

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.add(_controller.text.trim());
      _controller.clear();
    });

    saveMessages(); // Sauvegarde automatique à chaque message
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 0, // Index Conversations
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
          Expanded(
            child: ListView.builder(
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
