import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';

// بيانات الاختبار - احذفها لاحقاً
const _testUrl = 'http://mot9.sbs';
const _testUser = 'MS';
const _testPass = 'fdea99572f';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlCtrl = TextEditingController(text: _testUrl);
  final _userCtrl = TextEditingController(text: _testUser);
  final _passCtrl = TextEditingController(text: _testPass);
  final _urlFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _btnFocus = FocusNode();
  bool _loading = false;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (var f in [_urlFocus, _userFocus, _passFocus, _btnFocus]) {
      f.addListener(() => setState(() {}));
    }
    _checkSaved();
  }

  @override
  void dispose() {
    for (var f in [_urlFocus, _userFocus, _passFocus, _btnFocus]) f.dispose();
    super.dispose();
  }

  Future<void> _checkSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('credentials');
    if (saved != null && mounted) {
      final creds = XtreamCredentials.fromJson(jsonDecode(saved));
      _navigateHome(creds);
    } else {
      if (mounted) setState(() => _checking = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_urlFocus);
      });
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
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => HomeScreen(creds: creds),
      transitionDuration: Duration.zero,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(backgroundColor: Color(0xFF141414),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))));

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
              )),
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold, letterSpacing: -2)),
                    TextSpan(text: '⁹', style: TextStyle(color: Color(0xFFE50914), fontSize: 38, fontWeight: FontWeight.bold)),
                  ])),
                  const SizedBox(height: 12),
                  const Text('IPTV Player', style: TextStyle(color: Colors.white30, fontSize: 14, letterSpacing: 4)),
                ],
              )),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('أدخل بيانات Xtream', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 32),
                  _buildField('رابط الخادم', _urlCtrl, _urlFocus, _userFocus),
                  const SizedBox(height: 14),
                  _buildField('اسم المستخدم', _userCtrl, _userFocus, _passFocus),
                  const SizedBox(height: 14),
                  _buildField('كلمة المرور', _passCtrl, _passFocus, _btnFocus, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Color(0xFFE50914), fontSize: 12)),
                  ],
                  const SizedBox(height: 24),
                  _buildBtn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, FocusNode focus, FocusNode next, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: focus.hasFocus ? const Color(0xFFE50914) : Colors.transparent, width: 1.5),
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => FocusScope.of(context).requestFocus(next),
          ),
        ),
      ],
    );
  }

  Widget _buildBtn() {
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
          height: 46,
          decoration: BoxDecoration(
            color: _btnFocus.hasFocus ? const Color(0xFFB20710) : const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(5),
            boxShadow: _btnFocus.hasFocus ? [const BoxShadow(color: Color(0x66E50914), blurRadius: 12)] : [],
          ),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
