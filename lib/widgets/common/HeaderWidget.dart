import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: "Lens",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: "Family",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: CustomPaint(
              size: const Size(120, 80),
              painter: DiagonalStripesPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()..color = Colors.red;
    final yellowPaint = Paint()..color = Colors.yellow;

    final pathRed = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();

    final pathYellow = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.6, size.height)
      ..close();

    canvas.drawPath(pathRed, redPaint);
    canvas.drawPath(pathYellow, yellowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
