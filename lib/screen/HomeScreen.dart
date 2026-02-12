import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../layout/MainLayout.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String qrData = "";
  ui.Image? qrImage;
  Timer? timer;
  int secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    generateQRCode();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Génère un nouveau QR code
  void generateQRCode() async {
    qrData = DateTime.now().millisecondsSinceEpoch.toString() +
        "-" +
        Random().nextInt(1000).toString();
    secondsLeft = 15;

    // Crée l'image du QR code avec QrPainter
    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
    );

    final image = await qrPainter.toImage(250);
    setState(() {
      qrImage = image;
    });
  }

  // Timer pour le compte à rebours et le rafraîchissement
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (secondsLeft > 0) {
          secondsLeft--;
        } else {
          generateQRCode();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 1,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            qrImage != null
                ? SizedBox(
              width: 250,
              height: 250,
              child: RawImage(image: qrImage),
            )
                : const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "QR Code se rafraîchira dans $secondsLeft secondes",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
