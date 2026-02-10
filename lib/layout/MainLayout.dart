import 'package:flutter/material.dart';

import '../widgets/common/HeaderWidget.dart';
import '../widgets/common/FooterWidget.dart';
import '../widgets/common/FloatingRedButton.dart';

import '../screen/ScanPrairingScreen.dart';
import '../screen/ConversationScreen.dart';


class MainLayout extends StatelessWidget {
  final Widget body;
  final double floatingButtonBottom;
  final VoidCallback onFloatingTap;

  const MainLayout({
    super.key,
    required this.body,
    this.floatingButtonBottom = 35,
    required this.onFloatingTap,
  });

  void _goToScan(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanPairingScreen(),
      ),
    );
  }

  void _goToConversation(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const HeaderWidget(),
              Expanded(child: body),
              FooterWidget(
                onLeftTap: () => _goToConversation(context),
                onRightTap: () => _goToScan(context),
              ),
            ],
          ),

          // 🔴 bouton flottant
          Positioned(
            bottom: floatingButtonBottom,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: FloatingRedButton(
              onTap: onFloatingTap,
            ),
          ),
        ],
      ),
    );
  }
}
