import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;

  const FooterWidget({
    super.key,
    this.onLeftTap,
    this.onRightTap,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.people, size: 28),
                Text('Relations'),
              ],
            ),
          ),
          const SizedBox(width: 80), // espace pour le bouton rouge
          GestureDetector(
            onTap: onRightTap,
            child: Column(
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
