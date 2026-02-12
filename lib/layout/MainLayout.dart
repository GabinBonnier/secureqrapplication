import 'package:flutter/material.dart';
import 'package:secureqrapplication/screen/HomeScreen.dart';

import '../widgets/common/HeaderWidget.dart';
import '../widgets/common/FooterWidget.dart';
import '../widgets/common/FloatingRedButton.dart';

import '../screen/ScanPrairingScreen.dart';
import '../screen/ConversationScreen.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex; // 0 = Relations, 1 = Home, 2 = Scan

  const MainLayout({
    super.key,
    required this.body,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = const ConversationScreen();
        break;
      case 1:
        screen = const HomeScreen();
        break;
      case 2:
        screen = const ScanPairingScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double sectionWidth = screenWidth / 3;

    // Centre du bouton dans chaque section
    double leftPosition =
        (sectionWidth * currentIndex) + (sectionWidth / 2) - 35;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const HeaderWidget(),
              Expanded(child: body),
              FooterWidget(
                onLeftTap: () => _navigate(context, 0),
                onRightTap: () => _navigate(context, 2),
              ),
            ],
          ),

          // 🔴 Bouton rouge dynamique
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: 35,
            left: leftPosition,
            child: FloatingRedButton(
              onTap: () => _navigate(context, 1),
            ),
          ),
        ],
      ),
    );
  }
}
