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
  final _urlFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _btnFocus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlFocus.addListener(() => setState(() {}));
    _userFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
    _btnFocus.addListener(() => setState(() {}));
    _loadSaved();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_urlFocus);
    });
  }

  @override
  void dispose() {
    _urlFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _btnFocus.dispose();
    super.dispose();
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
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => HomeScreen(creds: creds),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Row(
        children: [
          // Left - branding
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                          text: 'mot',
                          style: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: -2),
                        ),
                        TextSpan(
                          text: '⁹',
                          style: TextStyle(color: Color(0xFFE50914), fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Text('IPTV Player', style: TextStyle(color: Colors.white38, fontSize: 18, letterSpacing: 4)),
                  ],
                ),
              ),
            ),
          ),
          // Right - form
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF141414),
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('أدخل بيانات Xtream الخاصة بك', style: TextStyle(color: Colors.white54, fontSize: 15)),
                  const SizedBox(height: 40),
                  _buildField('رابط الخادم', 'http://example.com:8080', _urlCtrl, _urlFocus, _userFocus),
                  const SizedBox(height: 20),
                  _buildField('اسم المستخدم', 'username', _userCtrl, _userFocus, _passFocus),
                  const SizedBox(height: 20),
                  _buildField('كلمة المرور', '••••••••', _passCtrl, _passFocus, _btnFocus, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 13)),
                  ],
                  const SizedBox(height: 32),
                  _buildLoginBtn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, FocusNode focusNode, FocusNode nextFocus, {bool obscure = false}) {
    final focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: focused ? const Color(0xFFE50914) : Colors.transparent, width: 2),
            boxShadow: focused ? [const BoxShadow(color: Color(0x44E50914), blurRadius: 8, spreadRadius: 1)] : [],
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginBtn() {
    final focused = _btnFocus.hasFocus;
    return Focus(
      focusNode: _btnFocus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
          if (!_loading) _login();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _loading ? null : _login,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: focused ? const Color(0xFFB20710) : const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(6),
            boxShadow: focused ? [const BoxShadow(color: Color(0x88E50914), blurRadius: 16, spreadRadius: 2)] : [],
          ),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}
