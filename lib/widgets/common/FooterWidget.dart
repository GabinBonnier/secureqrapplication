import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  final VoidCallback? onHomeTap; // Ajouté
  final int currentIndex; // 0 = Relations, 1 = QR-Code, 2 = Scan

  const FooterWidget({
    super.key,
    this.onLeftTap,
    this.onRightTap,
    this.onHomeTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: onLeftTap,
            child: currentIndex == 0
                ? const SizedBox(width: 60, height: 60) // masque l'icône dans le footer
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.people, size: 28),
                Text('Relations'),
              ],
            ),
          ),

          // Section centrale (Home)
          GestureDetector(
            onTap: onHomeTap, // <-- ici on ajoute le tap
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currentIndex == 1
                  ? const [SizedBox(width: 60, height: 60)] // masqué si Home actif
                  : const [
                Icon(Icons.qr_code, size: 28),
                Text('QR-Code'),
              ],
            ),
          ),

          // Section droite (Scan)
          GestureDetector(
            onTap: onRightTap,
            child: currentIndex == 2
                ? const SizedBox(width: 60, height: 60) // masque l'icône active
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.camera_alt, size: 28),
                Text('Scan'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
