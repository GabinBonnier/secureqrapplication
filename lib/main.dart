import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secureqrapplication/screen/HomeScreen.dart';
import 'screen/StartScreen.dart';
import 'firebase_options.dart'; // généré par FlutterFire CLI

void main() async {
  // Nécessaire pour l'initialisation Firebase avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lancement de l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LensFamily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const StartScreen(),
    );
  }
}
