import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../layout/MainLayout.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'ConversationScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String qrData = "";
  ui.Image? qrImage;
  Timer? timer;
  int secondsLeft = 15; // 15 secondes par cycle
  bool conversationReady = false; // Indique si quelqu'un a scanné

  @override
  void initState() {
    super.initState();
    generateQRCode();
    startTimer();
    checkConversationExistence();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Génère un nouveau QR code unique
  void generateQRCode() async {
    qrData = DateTime.now().millisecondsSinceEpoch.toString() +
        "-" +
        Random().nextInt(1000).toString();
    secondsLeft = 15;

    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
    );

    final image = await qrPainter.toImage(240);
    setState(() {
      qrImage = image;
      conversationReady = false; // Reset conversation
    });
  }

  // Vérifie en temps réel si quelqu'un a scanné le QR code
  void checkConversationExistence() {
    FirebaseFirestore.instance
        .collection('conversations')
        .doc(qrData)
        .snapshots()
        .listen((doc) {
      if (doc.exists && !conversationReady) {
        setState(() {
          conversationReady = true;
        });
      }
    });
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (secondsLeft > 0) {
          secondsLeft--;
        } else {
          generateQRCode();
          checkConversationExistence();
        }
      });
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
                    color: Colors.black.withOpacity(0.1),
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
                  qrImage != null
                      ? SizedBox(
                    width: 240,
                    height: 240,
                    child: RawImage(image: qrImage),
                  )
                      : const SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
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
                              ConversationScreen(partnerCode: qrData),
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
    );
  }
}
