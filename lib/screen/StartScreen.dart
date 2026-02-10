import 'package:flutter/material.dart';
import 'HomeScreen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFED1D29),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Clique pour continuer',
                  style: TextStyle(

                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
