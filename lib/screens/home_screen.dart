import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../services/tmdb_service.dart';
import '../services/watch_history_service.dart';
import '../utils/theme.dart';
import 'detail_screen.dart';
import 'player_screen.dart';
import 'live_screen.dart';
import 'vod_screen.dart';
import 'series_screen.dart';
import 'more_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 220),
);

// كم بوستر يظهر قبل زر "المزيد"
const int _rowLimit = 8;

class HomeScreen extends StatefulWidget {
  final XtreamCredentials creds;
  const HomeScreen({super.key, required this.creds});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late XtreamService _service;

  List<LiveChannel> _channels = [];
  List<VodItem> _vods = [];
  List<SeriesItem> _series = [];
  List<Category> _vodCats = [];
  List<Category> _seriesCats = [];
  List<Category> _liveCats = [];
  bool _loading = true;

  // Hero state — shared between tabs
  TmdbMovie? _heroTmdb;
  VodItem? _heroVod;
  bool _heroLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _service = XtreamService(widget.creds);
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
      _setInitialHero();
    }
  }

  Future<void> _setInitialHero() async {
    if (_vods.isEmpty) return;
    final idx = DateTime.now().millisecond % _vods.length;
    await _loadHero(_vods[idx]);
  }

  Future<void> _loadHero(VodItem vod) async {
    if (_heroLoading) return;
    setState(() => _heroLoading = true);
    final tmdb = await TmdbService.searchMovie(vod.name);
    if (mounted) setState(() { _heroVod = vod; _heroTmdb = tmdb; _heroLoading = false; });
  }

  void onPosterFocus(VodItem vod) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadHero(vod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : Stack(
              children: [
                // Page content
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _buildPage(),
                ),
                // Fixed header on top
                _TopHeader(
                  tab: _tab,
                  onTabChange: (t) => setState(() => _tab = t),
                ),
              ],
            ),
    );
  }

  Widget _buildPage() {
    switch (_tab) {
      case 1:
        return LiveScreen(service: _service, creds: widget.creds, channels: _channels, categories: _liveCats);
      case 2:
        return VodScreen(service: _service, creds: widget.creds, vods: _vods, categories: _vodCats);
      case 3:
        return SeriesScreen(service: _service, creds: widget.creds, series: _series, categories: _seriesCats);
      default:
        return _ForYouTab(
          vods: _vods,
          series: _series,
          vodCats: _vodCats,
          seriesCats: _seriesCats,
          creds: widget.creds,
          heroVod: _heroVod,
          heroTmdb: _heroTmdb,
          heroLoading: _heroLoading,
          onPosterFocus: onPosterFocus,
        );
    }
  }
}

// =================== FIXED TOP HEADER ===================

class _TopHeader extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTabChange;
  static const _tabs = [('For You', 0), ('Live', 1), ('Movies', 2), ('Series', 3)];

  const _TopHeader({required this.tab, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.95), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Logo
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -1)),
            TextSpan(text: '⁹', style: TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(width: 28),
          // Tabs
          ..._tabs.map((t) => _TabBtn(label: t.$1, selected: tab == t.$2, onTap: () => onTabChange(t.$2))),
          const Spacer(),
          // Icons
          _IconBtn(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.settings_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _TabBtn extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  State<_TabBtn> createState() => _TabBtnState();
}

class _TabBtnState extends State<_TabBtn> {
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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white
                : _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.black : (_focused ? Colors.white : Colors.white60),
              fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(widget.icon, color: _focused ? Colors.white : Colors.white70, size: 20),
        ),
      ),
    );
  }
}

// =================== FOR YOU TAB ===================

class _ForYouTab extends StatefulWidget {
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<Category> vodCats;
  final List<Category> seriesCats;
  final XtreamCredentials creds;
  final VodItem? heroVod;
  final TmdbMovie? heroTmdb;
  final bool heroLoading;
  final void Function(VodItem) onPosterFocus;

  const _ForYouTab({
    required this.vods, required this.series,
    required this.vodCats, required this.seriesCats,
    required this.creds, this.heroVod, this.heroTmdb,
    required this.heroLoading, required this.onPosterFocus,
  });

  @override
  State<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<_ForYouTab> {
  List<WatchEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await WatchHistoryService.getHistory();
    if (mounted) setState(() => _history = h);
  }

  @override
  Widget build(BuildContext context) {
    final tmdb = widget.heroTmdb;
    final vod = widget.heroVod;
    final backdropUrl = tmdb?.backdropUrl ?? vod?.poster;
    final title = tmdb?.title ?? vod?.name ?? '';
    final overview = tmdb?.overview ?? '';
    final year = tmdb?.year ?? '';
    final rating = tmdb?.ratingStr ?? '';
    final genre = tmdb?.genreStr ?? '';
    final runtime = tmdb?.runtimeStr ?? '';
    final logoUrl = tmdb?.logoUrl;

    return ListView(
      children: [
        // =================== HERO ===================
        Stack(
          children: [
            // Backdrop
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: backdropUrl != null
                  ? CachedNetworkImage(
                      key: ValueKey(backdropUrl),
                      imageUrl: backdropUrl,
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(height: 400, color: const Color(0xFF1A1A1A)),
                    )
                  : Container(key: const ValueKey('empty'), height: 400, color: const Color(0xFF1A1A1A)),
            ),
            // Left gradient
            Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.92), Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            // Bottom gradient
            Container(
              height: 400,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.0, 0.35],
                ),
              ),
            ),
            // Hero content
            Positioned(
              left: 28, bottom: 32, right: MediaQuery.of(context).size.width * 0.38,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo or title
                    if (logoUrl != null)
                      CachedNetworkImage(imageUrl: logoUrl, height: 52, fit: BoxFit.fitHeight,
                          errorWidget: (_, __, ___) => Text(title,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)))
                    else if (title.isNotEmpty)
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    // Meta row
                    Row(children: [
                      if (year.isNotEmpty) ...[
                        Text(year, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      if (rating.isNotEmpty) ...[
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                        const SizedBox(width: 3),
                        Text(rating, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 10),
                      ],
                      if (runtime.isNotEmpty) ...[
                        const Icon(Icons.access_time, color: Colors.white38, size: 12),
                        const SizedBox(width: 3),
                        Text(runtime, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ]),
                    if (genre.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(genre, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                    ],
                    if (overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(overview, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 16),
                    if (vod != null)
                      Row(children: [
                        _PlayBtn(onTap: () => Navigator.push(context, _fadeRoute(
                          PlayerScreen(id: vod.id, title: vod.name, url: vod.streamUrl(widget.creds), poster: vod.poster),
                        ))),
                        const SizedBox(width: 10),
                        _InfoBtn(onTap: () => Navigator.push(context, _fadeRoute(
                          MovieDetailScreen(item: vod, creds: widget.creds),
                        ))),
                      ]),
                  ],
                ),
              ),
            ),
            // Loading
            if (widget.heroLoading)
              const Positioned(top: 72, right: 16,
                child: SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 1.5))),
          ],
        ),

        const SizedBox(height: 24),

        // Continue watching
        if (_history.isNotEmpty) ...[
          _SectionLabel(title: 'متابعة المشاهدة'),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _history.length,
              itemBuilder: (_, i) => _ContinueCard(entry: _history[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // VOD rows
        ...widget.vodCats.take(4).map((cat) {
          final all = widget.vods.where((v) => v.categoryId == cat.id).toList();
          if (all.isEmpty) return const SizedBox();
          final shown = all.take(_rowLimit).toList();
          final hasMore = all.length > _rowLimit;
          return _HorizontalRow<VodItem>(
            title: cat.name,
            items: shown,
            hasMore: hasMore,
            imageBuilder: (v) => v.poster,
            nameBuilder: (v) => v.name,
            onFocus: (v) => widget.onPosterFocus(v),
            onTap: (v) => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: v, creds: widget.creds))),
            onMore: () => Navigator.push(context, _fadeRoute(MoreVodScreen(title: cat.name, items: all, creds: widget.creds))),
          );
        }),

        // Series rows
        ...widget.seriesCats.take(3).map((cat) {
          final all = widget.series.where((s) => s.categoryId == cat.id).toList();
          if (all.isEmpty) return const SizedBox();
          final shown = all.take(_rowLimit).toList();
          final hasMore = all.length > _rowLimit;
          return _HorizontalRow<SeriesItem>(
            title: cat.name,
            items: shown,
            hasMore: hasMore,
            imageBuilder: (s) => s.cover,
            nameBuilder: (s) => s.name,
            onFocus: (_) {},
            onTap: (_) {},
            onMore: () {},
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }
}

// =================== BUTTONS ===================

class _PlayBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayBtn({required this.onTap});

  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
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
          tween: Tween(begin: 1.0, end: _focused ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _focused ? Colors.white : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              boxShadow: _focused ? [const BoxShadow(color: Colors.white30, blurRadius: 12)] : [],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
              SizedBox(width: 6),
              Text('تشغيل', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InfoBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _InfoBtn({required this.onTap});

  @override
  State<_InfoBtn> createState() => _InfoBtnState();
}

class _InfoBtnState extends State<_InfoBtn> {
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
          tween: Tween(begin: 1.0, end: _focused ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _focused ? Colors.white24 : Colors.white12,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white38),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text('تفاصيل', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }
}

// =================== SECTION LABEL ===================

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
  );
}

// =================== CONTINUE WATCHING ===================

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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: 165,
            margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? const Color(0xFFE50914) : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                widget.entry.poster != null
                    ? CachedNetworkImage(imageUrl: widget.entry.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A2A)))
                    : Container(color: const Color(0xFF2A2A2A)),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                      decoration: BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      )),
                      child: Text(widget.entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    LinearProgressIndicator(
                      value: widget.entry.progress,
                      backgroundColor: Colors.white24,
                      color: const Color(0xFFE50914),
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
      id: widget.entry.id, title: widget.entry.name,
      url: widget.entry.url, poster: widget.entry.poster,
      startPositionMs: widget.entry.positionMs,
    )));
  }
}

// =================== HORIZONTAL ROW ===================

class _HorizontalRow<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final bool hasMore;
  final String? Function(T) imageBuilder;
  final String Function(T) nameBuilder;
  final void Function(T) onFocus;
  final void Function(T) onTap;
  final VoidCallback onMore;

  const _HorizontalRow({
    required this.title, required this.items, required this.hasMore,
    required this.imageBuilder, required this.nameBuilder,
    required this.onFocus, required this.onTap, required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    // Landscape card: 160×90
    const double cardW = 160;
    const double cardH = 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title),
        const SizedBox(height: 10),
        SizedBox(
          height: cardH + 16,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == items.length) {
                return _MoreCard(width: cardW, height: cardH, onTap: onMore);
              }
              return _LandscapeCard<T>(
                item: items[i],
                image: imageBuilder(items[i]),
                name: nameBuilder(items[i]),
                width: cardW,
                height: cardH,
                onFocus: () => onFocus(items[i]),
                onTap: () => onTap(items[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// =================== LANDSCAPE CARD ===================

class _LandscapeCard<T> extends StatefulWidget {
  final T item;
  final String? image;
  final String name;
  final double width;
  final double height;
  final VoidCallback onFocus;
  final VoidCallback onTap;

  const _LandscapeCard({super.key, required this.item, this.image, required this.name,
      required this.width, required this.height, required this.onFocus, required this.onTap});

  @override
  State<_LandscapeCard<T>> createState() => _LandscapeCardState<T>();
}

class _LandscapeCardState<T> extends State<_LandscapeCard<T>> {
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
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _focused ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? const Color(0xFFE50914) : Colors.transparent, width: 2),
              boxShadow: _focused ? [const BoxShadow(color: Colors.black87, blurRadius: 12, spreadRadius: 1)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                widget.image != null
                    ? CachedNetworkImage(imageUrl: widget.image!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                    )),
                    child: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A2A2A),
    child: const Icon(Icons.movie, color: Colors.white12, size: 28),
  );
}

// =================== MORE CARD ===================

class _MoreCard extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback onTap;
  const _MoreCard({required this.width, required this.height, required this.onTap});

  @override
  State<_MoreCard> createState() => _MoreCardState();
}

class _MoreCardState extends State<_MoreCard> {
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
          tween: Tween(begin: 1.0, end: _focused ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: _focused ? Colors.white12 : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? Colors.white38 : Colors.white12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 20),
                SizedBox(height: 6),
                Text('المزيد', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
