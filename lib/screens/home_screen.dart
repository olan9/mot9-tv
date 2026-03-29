import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../services/tmdb_service.dart';
import '../services/watch_history_service.dart';
import '../utils/theme.dart';
import '../widgets/side_nav.dart';
import 'login_screen.dart';
import 'live_screen.dart';
import 'vod_screen.dart';
import 'series_screen.dart';
import 'detail_screen.dart';
import 'player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final XtreamCredentials creds;
  const HomeScreen({super.key, required this.creds});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavItem _nav = NavItem.home;
  late XtreamService _service;

  List<LiveChannel> _channels = [];
  List<VodItem> _vods = [];
  List<SeriesItem> _series = [];
  List<Category> _vodCats = [];
  List<Category> _seriesCats = [];
  List<Category> _liveCats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = XtreamService(widget.creds);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _service.getLiveStreams(),
      _service.getVodStreams(),
      _service.getSeries(),
      _service.getVodCategories(),
      _service.getSeriesCategories(),
      _service.getLiveCategories(),
    ]);
    if (mounted) {
      setState(() {
        _channels = results[0] as List<LiveChannel>;
        _vods = results[1] as List<VodItem>;
        _series = results[2] as List<SeriesItem>;
        _vodCats = results[3] as List<Category>;
        _seriesCats = results[4] as List<Category>;
        _liveCats = results[5] as List<Category>;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('credentials');
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mot9Theme.bgColor,
      body: Row(
        children: [
          SideNav(
            selected: _nav,
            onSelect: (item) {
              if (item == NavItem.settings) {
                // فارغة حالياً
              } else {
                setState(() => _nav = item);
              }
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Mot9Theme.accentRed))
                : _buildPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_nav) {
      case NavItem.home:
        return _HomeTab(vods: _vods, series: _series, vodCats: _vodCats, seriesCats: _seriesCats, creds: widget.creds);
      case NavItem.movies:
        return VodScreen(service: _service, creds: widget.creds, vods: _vods, categories: _vodCats);
      case NavItem.series:
        return SeriesScreen(service: _service, creds: widget.creds, series: _series, categories: _seriesCats);
      case NavItem.live:
        return LiveScreen(service: _service, creds: widget.creds, channels: _channels, categories: _liveCats);
      default:
        return const Center(child: Text('الإعدادات', style: TextStyle(color: Colors.white)));
    }
  }
}

// =================== HOME TAB ===================

class _HomeTab extends StatefulWidget {
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<Category> vodCats;
  final List<Category> seriesCats;
  final XtreamCredentials creds;

  const _HomeTab({required this.vods, required this.series, required this.vodCats, required this.seriesCats, required this.creds});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  // Hero state
  TmdbMovie? _heroTmdb;
  VodItem? _heroVod;
  bool _heroLoading = false;

  // Continue watching
  List<WatchEntry> _history = [];

  // Focused item
  VodItem? _focusedVod;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setRandomHero();
  }

  Future<void> _loadHistory() async {
    final h = await WatchHistoryService.getHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _setRandomHero() async {
    if (widget.vods.isEmpty) return;
    final idx = DateTime.now().millisecond % widget.vods.length;
    final vod = widget.vods[idx];
    _updateHero(vod);
  }

  Future<void> _updateHero(VodItem vod) async {
    if (_heroLoading) return;
    _heroLoading = true;
    final tmdb = await TmdbService.searchMovie(vod.name);
    if (mounted) setState(() { _heroVod = vod; _heroTmdb = tmdb; _heroLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Hero
        _HeroBanner(
          vod: _heroVod,
          tmdb: _heroTmdb,
          creds: widget.creds,
        ),
        const SizedBox(height: 16),
        // Continue Watching
        if (_history.isNotEmpty)
          _ContinueWatchingRow(history: _history, creds: widget.creds),
        // Movie rows
        ...widget.vodCats.take(4).map((cat) {
          final items = widget.vods.where((v) => v.categoryId == cat.id).take(20).toList();
          if (items.isEmpty) return const SizedBox();
          return _ContentRow<VodItem>(
            title: cat.name,
            items: items,
            imageBuilder: (v) => v.poster,
            nameBuilder: (v) => v.name,
            onFocus: (v) => _updateHero(v),
            onTap: (v) => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: v, creds: widget.creds))),
          );
        }),
        // Series rows
        ...widget.seriesCats.take(3).map((cat) {
          final items = widget.series.where((s) => s.categoryId == cat.id).take(20).toList();
          if (items.isEmpty) return const SizedBox();
          return _ContentRow<SeriesItem>(
            title: cat.name,
            items: items,
            imageBuilder: (s) => s.cover,
            nameBuilder: (s) => s.name,
            onFocus: (_) {},
            onTap: (_) {},
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =================== HERO BANNER ===================

class _HeroBanner extends StatelessWidget {
  final VodItem? vod;
  final TmdbMovie? tmdb;
  final XtreamCredentials creds;

  const _HeroBanner({this.vod, this.tmdb, required this.creds});

  @override
  Widget build(BuildContext context) {
    final backdropUrl = tmdb?.backdropUrl ?? vod?.poster;
    final title = tmdb?.title ?? vod?.name ?? '';
    final overview = tmdb?.overview ?? '';
    final year = tmdb?.year ?? '';
    final rating = tmdb?.ratingStr ?? '';

    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop on right
          if (backdropUrl != null)
            CachedNetworkImage(imageUrl: backdropUrl, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)))
          else
            Container(color: const Color(0xFF1A1A1A)),
          // Gradient left
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Color(0xFF141414), Color(0xCC141414), Colors.transparent],
            stops: [0.0, 0.45, 0.75],
          ))),
          // Gradient bottom
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Color(0xFF141414), Colors.transparent],
            stops: [0.0, 0.4],
          ))),
          // Content left side
          Positioned(
            left: 32, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(children: [
                  if (year.isNotEmpty) ...[
                    Text(year, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 10),
                  ],
                  if (rating.isNotEmpty) ...[
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                    const SizedBox(width: 3),
                    Text(rating, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ]),
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(overview,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                if (vod != null)
                  Row(children: [
                    _HeroBtn(
                      icon: Icons.play_arrow_rounded,
                      label: 'تشغيل',
                      primary: true,
                      onTap: () => Navigator.push(context, _fadeRoute(
                        PlayerScreen(id: vod!.id, title: vod!.name, url: vod!.streamUrl(creds), poster: vod!.poster),
                      )),
                    ),
                    const SizedBox(width: 10),
                    _HeroBtn(
                      icon: Icons.info_outline_rounded,
                      label: 'تفاصيل',
                      primary: false,
                      onTap: () => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: vod!, creds: creds))),
                    ),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroBtn({required this.icon, required this.label, required this.primary, required this.onTap});

  @override
  State<_HeroBtn> createState() => _HeroBtnState();
}

class _HeroBtnState extends State<_HeroBtn> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.select) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_focused ? Colors.white : Colors.white.withOpacity(0.9))
                : (_focused ? Colors.white24 : Colors.white12),
            borderRadius: BorderRadius.circular(5),
            border: !widget.primary && _focused ? Border.all(color: Colors.white54) : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: widget.primary ? Colors.black : Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(widget.label, style: TextStyle(
              color: widget.primary ? Colors.black : Colors.white,
              fontSize: 13, fontWeight: FontWeight.bold,
            )),
          ]),
        ),
      ),
    );
  }
}

// =================== CONTINUE WATCHING ===================

class _ContinueWatchingRow extends StatelessWidget {
  final List<WatchEntry> history;
  final XtreamCredentials creds;

  const _ContinueWatchingRow({required this.history, required this.creds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text('متابعة المشاهدة', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: history.length,
            itemBuilder: (_, i) => _ContinueCard(entry: history[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ContinueCard extends StatefulWidget {
  final WatchEntry entry;
  const _ContinueCard({required this.entry});

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.select) {
          Navigator.push(context, _fadeRoute(PlayerScreen(
            id: widget.entry.id,
            title: widget.entry.name,
            url: widget.entry.url,
            poster: widget.entry.poster,
            startPositionMs: widget.entry.positionMs,
          )));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => Navigator.push(context, _fadeRoute(PlayerScreen(
          id: widget.entry.id,
          title: widget.entry.name,
          url: widget.entry.url,
          poster: widget.entry.poster,
          startPositionMs: widget.entry.positionMs,
        ))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 180,
          margin: EdgeInsets.only(right: 10, top: _focused ? 0 : 6, bottom: _focused ? 0 : 6),
          transform: _focused ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.entry.poster != null
                    ? CachedNetworkImage(imageUrl: widget.entry.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Mot9Theme.cardColor))
                    : Container(color: Mot9Theme.cardColor),
                // Progress bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                      decoration: const BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      )),
                      child: Text(widget.entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    LinearProgressIndicator(
                      value: widget.entry.progress,
                      backgroundColor: Colors.white24,
                      color: Mot9Theme.accentRed,
                      minHeight: 3,
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================== CONTENT ROW ===================

class _ContentRow<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String? Function(T) imageBuilder;
  final String Function(T) nameBuilder;
  final void Function(T) onFocus;
  final void Function(T) onTap;

  const _ContentRow({
    required this.title,
    required this.items,
    required this.imageBuilder,
    required this.nameBuilder,
    required this.onFocus,
    required this.onTap,
  });

  @override
  State<_ContentRow<T>> createState() => _ContentRowState<T>();
}

class _ContentRowState<T> extends State<_ContentRow<T>> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.items.length,
            itemBuilder: (_, i) => _PosterCard<T>(
              item: widget.items[i],
              image: widget.imageBuilder(widget.items[i]),
              name: widget.nameBuilder(widget.items[i]),
              onFocus: () => widget.onFocus(widget.items[i]),
              onTap: () => widget.onTap(widget.items[i]),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PosterCard<T> extends StatefulWidget {
  final T item;
  final String? image;
  final String name;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  const _PosterCard({super.key, required this.item, this.image, required this.name, required this.onFocus, required this.onTap});

  @override
  State<_PosterCard<T>> createState() => _PosterCardState<T>();
}

class _PosterCardState<T> extends State<_PosterCard<T>> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      if (_focus.hasFocus) widget.onFocus();
    });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.select) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 100,
          margin: EdgeInsets.only(right: 8, top: _focused ? 0 : 8, bottom: _focused ? 0 : 8),
          transform: _focused ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            boxShadow: _focused ? [const BoxShadow(color: Colors.black87, blurRadius: 16, spreadRadius: 2)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.image != null
                    ? CachedNetworkImage(imageUrl: widget.image!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 14, 5, 5),
                    decoration: const BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    )),
                    child: Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(color: Mot9Theme.cardColor,
      child: const Icon(Icons.movie, color: Colors.white12, size: 28));
}

// =================== HELPERS ===================

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 250),
);
