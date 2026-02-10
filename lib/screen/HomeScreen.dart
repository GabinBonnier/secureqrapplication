import 'package:flutter/material.dart';
import 'ScanPrairingScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialisation'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanPairingScreen(),
              ),
            );
          },
          child: const Text('Aller à la page suivante'),
        ),
      ),
    );
  }
}