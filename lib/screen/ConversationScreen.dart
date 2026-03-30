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
  final TextEditingController _controller = TextEditingController();
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
    // Polling toutes les 5 secondes pour synchroniser les 2 appareils
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        fetchMessages();
        checkKeysReady();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> checkKeysReady() async {
    try {
      final keyStore = RelationshipKeyStorage();
      final partnerKey = await keyStore.readPartnerPublicKey(widget.conversationId);
      final keysR = partnerKey != null;
      final status = keysR ? 'Clés RSA prêtes ✅' : 'Attente des clés du partenaire... ⏳';
      if (mounted) {
        setState(() {
          keysReady = keysR;
          keyStatus = status;
        });
      }
    } catch (e) {
      if (mounted) setState(() => keyStatus = 'Erreur clés: $e');
    }
  }

  Future<void> fetchMessages() async {
    // Pas de setState isLoading=true ici pour éviter le flash à chaque poll
    try {
      final result = await ElementService.fetchElements(widget.conversationId);
      if (mounted) {
        setState(() {
          messages = result;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur récupération : $e';
        });
      }
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final ok = await ElementService.sendElement(
        relationCode: widget.conversationId,
        type: 'MESSAGE',
        value: text,
      );
      if (ok) {
        _controller.clear();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Conversation avec ${widget.conversationId}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Key status indicator
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: keysReady ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(keysReady ? Icons.security : Icons.hourglass_empty, 
                           size: 16,
                           color: keysReady ? Colors.green : Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(child: Text(keyStatus ?? 'Vérification...', 
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: keysReady ? Colors.green[800] : Colors.orange[800],
                                          ))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bandeau erreur
          if (errorMessage != null)
            Container(
              color: Colors.red[50],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => errorMessage = null),
                  ),
                ],
              ),
            ),

          // Liste des messages
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchMessages,
              child: messages.isEmpty
                  ? const Center(child: Text('Aucun message.'))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(msg['value'] ?? ''),
                        );
                      },
                    ),
            ),
          ),

          // Champ d'envoi
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
                  icon: Icon(Icons.send, color: (isLoading || !keysReady) ? Colors.grey : Colors.red),
                  onPressed: (isLoading || !keysReady) ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
