import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/MainLayout.dart';
import 'ConversationScreen.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  List<String> conversationKeys = [];

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  // Charger toutes les conversations stockées (clé 'conversations')
  Future<void> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      conversationKeys = prefs.getStringList('conversations') ?? [];
    });
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
            child: const Text(
              "Mes conversations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: conversationKeys.isEmpty
                ? const Center(
              child: Text(
                "Aucune conversation pour le moment",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: conversationKeys.length,
              itemBuilder: (context, index) {
                final conversationId = conversationKeys[index];
                return GestureDetector(
                  onTap: () {
                    // Ouvre la conversation sélectionnée
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ConversationScreen(conversationId: conversationId),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversationId,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
