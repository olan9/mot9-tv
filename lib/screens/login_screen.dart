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

  final _urlFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _btnFocus = FocusNode();

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
      if (mounted) {
        _navigateHome(creds);
      }
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A), Color(0xFF0A0A14)],
              ),
            ),
          ),
          // Logo top-left
          Positioned(
            top: 40, left: 60,
            child: _buildLogo(size: 36),
          ),
          // Form center
          Center(
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: const Color(0xFF141414).withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('أدخل بيانات Xtream الخاصة بك', style: TextStyle(color: Mot9Theme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 32),
                  _buildField('رابط الخادم', 'http://example.com:8080', _urlCtrl, _urlFocus, _userFocus),
                  const SizedBox(height: 16),
                  _buildField('اسم المستخدم', 'username', _userCtrl, _userFocus, _passFocus),
                  const SizedBox(height: 16),
                  _buildField('كلمة المرور', '••••••••', _passCtrl, _passFocus, _btnFocus, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Mot9Theme.accentRed, fontSize: 13)),
                  ],
                  const SizedBox(height: 28),
                  _buildLoginBtn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double size = 28}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: size, fontWeight: FontWeight.bold, letterSpacing: -1)),
          TextSpan(text: '⁹', style: TextStyle(color: Mot9Theme.accentRed, fontSize: size * 0.75, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, FocusNode focus, FocusNode nextFocus, {bool obscure = false}) {
    return Focus(
      focusNode: focus,
      child: Builder(builder: (ctx) {
        final isFocused = Focus.of(ctx).hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Mot9Theme.textSecondary, fontSize: 12, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              focusNode: focus,
              obscureText: obscure,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF555555)),
                filled: true,
                fillColor: const Color(0xFF333333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Mot9Theme.accentRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLoginBtn() {
    return Focus(
      focusNode: _btnFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          _login();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: _loading ? null : _login,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: focused ? Mot9Theme.accentRedDark : Mot9Theme.accentRed,
              borderRadius: BorderRadius.circular(4),
              boxShadow: focused ? [const BoxShadow(color: Mot9Theme.accentRed, blurRadius: 12, spreadRadius: 1)] : [],
            ),
            alignment: Alignment.center,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }
}
