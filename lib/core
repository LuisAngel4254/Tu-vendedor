// main.dart
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // descomentar tras agregar google-services.json
import 'screens/perfil_negocio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // descomentar tras configurar Firebase
  runApp(const AsaiLocalApp());
}

class AsaiLocalApp extends StatelessWidget {
  const AsaiLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asai — Panel del local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E3B)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const PerfilNegocioScreen(),
    );
  }
}

