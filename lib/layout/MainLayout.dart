import 'package:flutter/material.dart';
import 'package:secureqrapplication/screen/HomeScreen.dart';

import '../widgets/common/HeaderWidget.dart';
import '../widgets/common/FooterWidget.dart';
import '../widgets/common/FloatingRedButton.dart';

import '../screen/ScanPrairingScreen.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex; // 0 = Conversations, 1 = Home, 2 = Scan

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
      // Écran Conversations – navigation via ScanPairingScreen, donc ici on peut juste mettre un écran vide ou la liste des conversations
        screen = const HomeScreen(); // remplacer par ta liste de conversations si tu en as
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

    // Position horizontale du bouton rouge (menu)
    double leftPosition =
        (sectionWidth * currentIndex) + (sectionWidth / 2) - 35;

    double bottomPosition = 55;

    // Choix de l'icône selon la page
    IconData icon;
    switch (currentIndex) {
      case 0:
        icon = Icons.people;
        break;
      case 1:
        icon = Icons.qr_code;
        break;
      case 2:
        icon = Icons.camera_alt;
        break;
      default:
        icon = Icons.qr_code;
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const HeaderWidget(),
              Expanded(child: body),
              FooterWidget(
                currentIndex: currentIndex,
                onLeftTap: () => _navigate(context, 0),
                onRightTap: () => _navigate(context, 2),
                onHomeTap: () => _navigate(context, 1),
              ),
            ],
          ),

          // Bouton rouge du menu qui s'adapte selon l'onglet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: bottomPosition,
            left: leftPosition,
            child: FloatingRedButton(
              onTap: () {
                if (currentIndex != 1) _navigate(context, 1);
              },
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }
}
