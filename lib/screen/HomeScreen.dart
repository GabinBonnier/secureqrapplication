import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/MainLayout.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ConversationScreen.dart';
import '../services/PairingService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String relationCode = "";
  Timer? timer;
  Timer? pollingTimer;
  int secondsLeft = 120; // 2 minutes timeout
  bool conversationReady = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    createNewPairing();
  }

  @override
  void dispose() {
    timer?.cancel();
    pollingTimer?.cancel();
    super.dispose();
  }

  // cree un nouveau pairing via l'API
  void createNewPairing() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      conversationReady = false;
      relationCode = "";
    });

    try {
      // on cree le pairing sur le serveur
      String code = await PairingService.createPairing();
      
      debugPrint("Pairing cree: $code");

      if (!mounted) return;
      setState(() {
        relationCode = code;
        isLoading = false;
        secondsLeft = 120;
      });

      // on demarre le timer et le polling
      startTimer();
      startPolling();
      
    } catch (e, stack) {
      debugPrint("Erreur creation pairing: $e");
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Erreur lors de la génération des clés RSA ou du pairing : $e";
      });
    }
  }

  // polling toutes les 3 secondes
  void startPolling() {
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (relationCode.isEmpty || conversationReady) return;
      try {
        String? status = await PairingService.checkPairingStatus(relationCode);
        debugPrint("Status du pairing: $status");
        if (status == "completed") {
          // L'autre utilisateur a scanné ! On finalise pour récupérer ses infos
          pollingTimer?.cancel();
          var result = await PairingService.finalizePairing(relationCode);
          if (result != null) {
            debugPrint("Pairing finalisé, prêt pour conversation !");
            // Sauvegarder la conversation dans SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final conversations = prefs.getStringList('conversations') ?? [];
            if (!conversations.contains(relationCode)) {
              conversations.add(relationCode);
              await prefs.setStringList('conversations', conversations);
            }
            if (mounted) {
              setState(() { conversationReady = true; });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(conversationId: relationCode),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      }
    });
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (secondsLeft > 0) {
        setState(() { secondsLeft--; });
      } else {
        // timeout - on recree
        timer?.cancel();
        pollingTimer?.cancel();
        createNewPairing();
      }
    });
  }

  // Formate le temps restant
  String get formattedTime {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      body: Container(
        color: const Color(0xFFDCCACA),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.red, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset('assets/logo.png'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Votre Pass Supporter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Génération des clés RSA, cela peut prendre quelques secondes...',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          )
                        : errorMessage != null
                            ? SizedBox(
                                width: 240,
                                height: 240,
                                child: Center(
                                  child: Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: 240,
                                height: 240,
                                child: QrImageView(
                                  data: relationCode,
                                  version: QrVersions.auto,
                                  size: 240,
                                ),
                              ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scannez ce code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Ce QR code expire dans",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: conversationReady
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ConversationScreen(conversationId: relationCode),
                          ),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: conversationReady ? Colors.red : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Ouvrir la conversation",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
