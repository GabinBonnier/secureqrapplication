import 'package:flutter/material.dart';

class home_screen extends StatelessWidget {
  const home_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialisation'),
      ),
      body: const Center(
        child: Text(
          'Page suivante',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
