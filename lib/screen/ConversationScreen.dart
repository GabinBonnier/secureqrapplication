import 'package:flutter/material.dart';
import '../layout/MainLayout.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      onFloatingTap: () {},
      body: const Center(
        child: Text('Page Conversations'),
      ),
    );
  }
}
