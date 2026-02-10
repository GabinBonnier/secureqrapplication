import 'package:flutter/material.dart';
import 'ScanPrairingScreen.dart';
import '../widgets/common/HeaderWidget.dart';
import '../widgets/common/FloatingRedButton.dart';
import '../widgets/common/FooterWidget.dart';
import '../layout/MainLayout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      floatingButtonBottom: 35, // position classique
      onFloatingTap: () {
        print('QR tapped');
      },
      body: const Center(
        child: Text('Home'),
      ),
    );
  }
}
