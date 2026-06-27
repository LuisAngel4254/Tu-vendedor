import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pvmhgqmarshjkmbnclqj.supabase.co',
    anonKey: 'sb_publishable_KPwoyQ1eVh7PoMUJt0VHIA_cdc7sKrZ',
  );

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
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E3B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
