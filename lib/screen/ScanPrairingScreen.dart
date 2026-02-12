import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../layout/MainLayout.dart';
import 'ConversationScreen.dart';

class ScanPairingScreen extends StatefulWidget {
  const ScanPairingScreen({super.key});

  @override
  State<ScanPairingScreen> createState() => _ScanPairingScreenState();
}

class _ScanPairingScreenState extends State<ScanPairingScreen> {
  String? scannedCode;
  bool hasNavigated = false; // pour éviter de lancer plusieurs fois la navigation

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
      body: Container(
        color: const Color(0xFFE4CECE),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scanner un QR-code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: MobileScanner(
                        onDetect: (BarcodeCapture capture) {
                          final String? code = capture.barcodes.first.rawValue;

                          if (code != null && !hasNavigated) {
                            scannedCode = code;
                            hasNavigated = true;

                            // Afficher une pop-up pour confirmer la connexion
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Invitation reçue"),
                                content: Text(
                                    "Voulez-vous démarrer une conversation avec $code ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      hasNavigated = false; // reset si annulation
                                    },
                                    child: const Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      // Naviguer vers ConversationScreen avec le partnerCode
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConversationScreen(
                                                  partnerCode: scannedCode!),
                                        ),
                                      );
                                    },
                                    child: const Text("Accepter"),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (scannedCode != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Code scanné : $scannedCode",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
