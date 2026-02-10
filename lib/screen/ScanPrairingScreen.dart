import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPairingScreen extends StatelessWidget {
  const ScanPairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4CECE),
      appBar: AppBar(
        title: const Text('Initialisation'),
        backgroundColor: const Color(0xFFE4CECE),
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Texte
          const Text(
            'Scanner un QR-code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // Zone caméra
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
                        final String? code =
                            capture.barcodes.first.rawValue;
                        if (code != null) {
                          debugPrint('QR scanné : $code');
                        }
                      },
                    ),
                  ),
                ),

                // Cadre blanc
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
        ],
      ),
    );
  }
}
