import 'dart:async';
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

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 220),
);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Row(
        children: [
          SideNav(
            selected: _nav,
            onSelect: (item) {
              if (item == NavItem.settings) return;
              setState(() => _nav = item);
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
        return const SizedBox();
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
  TmdbMovie? _heroTmdb;
  VodItem? _heroVod;
  bool _heroLoading = false;
  Timer? _debounce;
  List<WatchEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setInitialHero();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await WatchHistoryService.getHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _setInitialHero() async {
    if (widget.vods.isEmpty) return;
    final idx = DateTime.now().millisecond % widget.vods.length;
    await _loadHero(widget.vods[idx]);
  }

  Future<void> _loadHero(VodItem vod) async {
    if (_heroLoading) return;
    setState(() => _heroLoading = true);
    final tmdb = await TmdbService.searchMovie(vod.name);
    if (mounted) setState(() { _heroVod = vod; _heroTmdb = tmdb; _heroLoading = false; });
  }

  void _onFocus(VodItem vod) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadHero(vod));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero — ثابت فوق
        _DynamicHero(vod: _heroVod, tmdb: _heroTmdb, loading: _heroLoading, creds: widget.creds),
        // Scrollable rows تحت
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (_history.isNotEmpty)
                _ContinueWatchingRow(history: _history),
              ...widget.vodCats.take(4).map((cat) {
                final items = widget.vods.where((v) => v.categoryId == cat.id).take(20).toList();
                if (items.isEmpty) return const SizedBox();
                return _ContentRow<VodItem>(
                  title: cat.name,
                  items: items,
                  imageBuilder: (v) => v.poster,
                  nameBuilder: (v) => v.name,
                  onFocus: (v) => _onFocus(v),
                  onTap: (v) => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: v, creds: widget.creds))),
                );
              }),
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
            ],
          ),
        ),
      ],
    );
  }
}

// =================== DYNAMIC HERO ===================

class _DynamicHero extends StatelessWidget {
  final VodItem? vod;
  final TmdbMovie? tmdb;
  final bool loading;
  final XtreamCredentials creds;

  const _DynamicHero({this.vod, this.tmdb, required this.loading, required this.creds});

  @override
  Widget build(BuildContext context) {
    final backdropUrl = tmdb?.backdropUrl ?? vod?.poster;
    final title = tmdb?.title ?? vod?.name ?? '';
    final overview = tmdb?.overview ?? '';
    final year = tmdb?.year ?? '';
    final rating = tmdb?.ratingStr ?? '';

    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop with animated switch
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: backdropUrl != null
                ? CachedNetworkImage(
                    key: ValueKey(backdropUrl),
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
                  )
                : Container(key: const ValueKey('empty'), color: const Color(0xFF1A1A1A)),
          ),
          // Left gradient
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Color(0xFF141414), Color(0xCC141414), Colors.transparent],
            stops: [0.0, 0.4, 0.7],
          ))),
          // Bottom gradient
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Color(0xFF141414), Colors.transparent],
            stops: [0.0, 0.35],
          ))),
          // Content — animated switch
          Positioned(
            left: 28, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(title),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title.isNotEmpty)
                    Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 5),
                  Row(children: [
                    if (year.isNotEmpty) ...[
                      Text(year, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 10),
                    ],
                    if (rating.isNotEmpty) ...[
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
                      const SizedBox(width: 3),
                      Text(rating, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ]),
                  if (overview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(overview,
                      style: const TextStyle(color: Colors.white45, fontSize: 11, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
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
                      const SizedBox(width: 8),
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
          ),
          // Loading indicator
          if (loading)
            const Positioned(top: 16, right: 16,
              child: SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(color: Mot9Theme.accentRed, strokeWidth: 1.5))),
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
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _focused ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.primary
                  ? (_focused ? Colors.white : Colors.white.withOpacity(0.88))
                  : (_focused ? Colors.white20 : Colors.white10),
              borderRadius: BorderRadius.circular(4),
              border: !widget.primary ? Border.all(color: _focused ? Colors.white38 : Colors.transparent) : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, color: widget.primary ? Colors.black : Colors.white, size: 16),
              const SizedBox(width: 5),
              Text(widget.label, style: TextStyle(
                color: widget.primary ? Colors.black : Colors.white,
                fontSize: 12, fontWeight: FontWeight.bold,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// =================== CONTINUE WATCHING ===================

class _ContinueWatchingRow extends StatelessWidget {
  final List<WatchEntry> history;
  const _ContinueWatchingRow({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text('متابعة المشاهدة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: history.length,
            itemBuilder: (_, i) => _ContinueCard(entry: history[i]),
          ),
        ),
        const SizedBox(height: 4),
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
          _open(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _open(context),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _focused ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 170,
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(fit: StackFit.expand, children: [
                widget.entry.poster != null
                    ? CachedNetworkImage(imageUrl: widget.entry.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Mot9Theme.cardColor))
                    : Container(color: Mot9Theme.cardColor),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 3),
                      decoration: const BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      )),
                      child: Text(widget.entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                    LinearProgressIndicator(
                      value: widget.entry.progress,
                      backgroundColor: Colors.white24,
                      color: Mot9Theme.accentRed,
                      minHeight: 2.5,
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.push(context, _fadeRoute(PlayerScreen(
      id: widget.entry.id,
      title: widget.entry.name,
      url: widget.entry.url,
      poster: widget.entry.poster,
      startPositionMs: widget.entry.positionMs,
    )));
  }
}

// =================== CONTENT ROW ===================

class _ContentRow<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String? Function(T) imageBuilder;
  final String Function(T) nameBuilder;
  final void Function(T) onFocus;
  final void Function(T) onTap;

  const _ContentRow({
    required this.title, required this.items,
    required this.imageBuilder, required this.nameBuilder,
    required this.onFocus, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (_, i) => _PosterCard<T>(
              item: items[i],
              image: imageBuilder(items[i]),
              name: nameBuilder(items[i]),
              onFocus: () => onFocus(items[i]),
              onTap: () => onTap(items[i]),
            ),
          ),
        ),
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

  // Fixed dimensions
  static const double _w = 96.0;
  static const double _h = 144.0;

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
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _focused ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: _w,
            height: _h,
            margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _focused ? Mot9Theme.accentRed : Colors.transparent,
                width: 2,
              ),
              boxShadow: _focused
                  ? [const BoxShadow(color: Colors.black87, blurRadius: 14, spreadRadius: 2)]
                  : [],
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
                      padding: const EdgeInsets.fromLTRB(5, 12, 5, 5),
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
      ),
    );
  }

  Widget _placeholder() => Container(color: Mot9Theme.cardColor,
      child: const Icon(Icons.movie, color: Colors.white12, size: 24));
}
