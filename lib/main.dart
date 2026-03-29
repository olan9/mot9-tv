import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Mot9App());
}

class Mot9App extends StatelessWidget {
  const Mot9App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mot⁹',
      debugShowCheckedModeBanner: false,
      theme: Mot9Theme.theme,
      home: const LoginScreen(),
    );
  }
}