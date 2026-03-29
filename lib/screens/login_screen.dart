import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _focused = 0;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('credentials');
    if (saved != null) {
      final creds = XtreamCredentials.fromJson(jsonDecode(saved));
      if (mounted) _navigateHome(creds);
    }
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final creds = XtreamCredentials(
      url: _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), ''),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    final ok = await XtreamService(creds).login();
    if (!mounted) return;
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('credentials', jsonEncode(creds.toJson()));
      _navigateHome(creds);
    } else {
      setState(() { _loading = false; _error = 'فشل الاتصال. تحقق من البيانات.'; });
    }
  }

  void _navigateHome(XtreamCredentials creds) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(creds: creds)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mot9Theme.bgColor,
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() => _focused = (_focused + 1).clamp(0, 3));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() => _focused = (_focused - 1).clamp(0, 3));
            } else if (event.logicalKey == LogicalKeyboardKey.select && _focused == 3) {
              _login();
            }
          }
        },
        child: Center(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: const TextSpan(children: [
                  TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  TextSpan(text: '⁹', style: TextStyle(color: Mot9Theme.accentRed, fontSize: 27, fontWeight: FontWeight.bold)),
                ])),
                const SizedBox(height: 32),
                const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('أدخل بيانات Xtream', style: TextStyle(color: Mot9Theme.textSecondary)),
                const SizedBox(height: 32),
                _buildField('رابط الخادم', _urlCtrl, 0),
                const SizedBox(height: 16),
                _buildField('اسم المستخدم', _userCtrl, 1),
                const SizedBox(height: 16),
                _buildField('كلمة المرور', _passCtrl, 2, obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Mot9Theme.accentRed)),
                ],
                const SizedBox(height: 24),
                _buildBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, int index, {bool obscure = false}) {
    final isFocused = _focused == index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Mot9Theme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isFocused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            autofocus: index == 0,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onTap: () => setState(() => _focused = index),
            onSubmitted: (_) => setState(() => _focused = index + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildBtn() {
    final isFocused = _focused == 3;
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: isFocused ? Mot9Theme.accentRedDark : Mot9Theme.accentRed,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isFocused ? [const BoxShadow(color: Mot9Theme.accentRed, blurRadius: 12)] : [],
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
