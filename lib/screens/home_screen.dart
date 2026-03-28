import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import '../widgets/content_row.dart';
import '../widgets/hero_banner.dart';
import 'live_screen.dart';
import 'vod_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final XtreamCredentials creds;
  const HomeScreen({super.key, required this.creds});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late XtreamService _service;

  final _tabs = ['🏠 الرئيسية', '📺 بث مباشر', '🎬 أفلام'];
  final _navFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _service = XtreamService(widget.creds);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('credentials');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mot9Theme.bgColor,
      body: Column(
        children: [
          _buildNavBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          // Logo
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
                TextSpan(text: '⁹', style: TextStyle(color: Mot9Theme.accentRed, fontSize: 21, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // Tabs
          ..._tabs.asMap().entries.map((e) => _buildNavItem(e.key, e.value)),
          const Spacer(),
          // Logout
          _buildNavAction(3, Icons.logout, _logout),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label) {
    final selected = _tab == index;
    return Focus(
      focusNode: _navFocusNodes[index],
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          setState(() => _tab = index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: selected ? Mot9Theme.accentRed : (focused ? Colors.white54 : Colors.transparent),
                width: 2,
              )),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (focused ? Colors.white : Colors.white60),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavAction(int index, IconData icon, VoidCallback onTap) {
    return Focus(
      focusNode: _navFocusNodes[index],
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: focused ? Colors.white12 : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
        );
      }),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return _HomeTab(service: _service, creds: widget.creds);
      case 1:
        return LiveScreen(service: _service, creds: widget.creds);
      case 2:
        return VodScreen(service: _service, creds: widget.creds);
      default:
        return const SizedBox();
    }
  }
}

class _HomeTab extends StatefulWidget {
  final XtreamService service;
  final XtreamCredentials creds;
  const _HomeTab({required this.service, required this.creds});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Category> _liveCategories = [];
  List<LiveChannel> _liveChannels = [];
  List<Category> _vodCategories = [];
  List<VodItem> _vodItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.service.getLiveCategories(),
        widget.service.getLiveStreams(),
        widget.service.getVodCategories(),
        widget.service.getVodStreams(),
      ]);
      if (mounted) {
        setState(() {
          _liveCategories = results[0] as List<Category>;
          _liveChannels = results[1] as List<LiveChannel>;
          _vodCategories = results[2] as List<Category>;
          _vodItems = results[3] as List<VodItem>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Mot9Theme.accentRed));
    }

    return ListView(
      children: [
        // Hero banner - first channel with logo
        if (_liveChannels.isNotEmpty)
          HeroBanner(channel: _liveChannels.first, creds: widget.creds),
        const SizedBox(height: 24),
        // Live rows per category
        ..._liveCategories.take(4).map((cat) {
          final channels = _liveChannels.where((c) => c.categoryId == cat.id).toList();
          if (channels.isEmpty) return const SizedBox();
          return ContentRow<LiveChannel>(
            title: cat.name,
            items: channels,
            imageBuilder: (c) => c.logo,
            nameBuilder: (c) => c.name,
            onTap: (c) => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlayerPlaceholder(title: c.name, url: c.streamUrl(widget.creds)),
            )),
          );
        }),
        const SizedBox(height: 8),
        // VOD rows
        ..._vodCategories.take(4).map((cat) {
          final vods = _vodItems.where((v) => v.categoryId == cat.id).toList();
          if (vods.isEmpty) return const SizedBox();
          return ContentRow<VodItem>(
            title: cat.name,
            items: vods,
            imageBuilder: (v) => v.poster,
            nameBuilder: (v) => v.name,
            onTap: (v) => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlayerPlaceholder(title: v.name, url: v.streamUrl(widget.creds)),
            )),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }
}

class PlayerPlaceholder extends StatelessWidget {
  final String title;
  final String url;
  const PlayerPlaceholder({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: Text('▶ $title\n$url', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
  );
}
