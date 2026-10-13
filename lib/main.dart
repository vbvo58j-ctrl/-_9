import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BluetoothWhatsAppApp());
}

class BluetoothWhatsAppApp extends StatelessWidget {
  const BluetoothWhatsAppApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Chat',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
        ),
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
      ),
      home: const HomeScreen(),
    );
  }
}