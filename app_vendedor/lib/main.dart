import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(const TuVendedorApp());
}

class TuVendedorApp extends StatelessWidget {
  const TuVendedorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Vendedor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E3B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
