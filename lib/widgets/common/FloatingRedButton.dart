import 'package:flutter/material.dart';

class FloatingRedButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingRedButton({super.key, required this.onTap});

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
        child: const Center(
          child: Icon(
            Icons.qr_code,
            color: Colors.black,
            size: 32,
          ),
        ),
      ),
    );
  }
}
