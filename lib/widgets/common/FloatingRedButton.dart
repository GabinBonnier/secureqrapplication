import 'package:flutter/material.dart';

class FloatingRedButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon; // Icône dynamique

  const FloatingRedButton({
    super.key,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}
