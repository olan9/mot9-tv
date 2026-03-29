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
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

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
  int _tab = 0; // 0=ForYou, 1=Live, 2=Movies, 3=Series
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
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 1:
        return _withHeader(LiveScreen(service: _service, creds: widget.creds, channels: _channels, categories: _liveCats));
      case 2:
        return _withHeader(VodScreen(service: _service, creds: widget.creds, vods: _vods, categories: _vodCats));
      case 3:
        return _withHeader(SeriesScreen(service: _service, creds: widget.creds, series: _series, categories: _seriesCats));
      default:
        return _ForYouTab(
          vods: _vods,
          series: _series,
          vodCats: _vodCats,
          seriesCats: _seriesCats,
          channels: _channels,
          creds: widget.creds,
          tab: _tab,
          onTabChange: (t) => setState(() => _tab = t),
        );
    }
  }

  Widget _withHeader(Widget child) {
    return Column(
      children: [
        _TopHeader(tab: _tab, onTabChange: (t) => setState(() => _tab = t)),
        Expanded(child: child),
      ],
    );
  }
}

// =================== TOP HEADER ===================

class _TopHeader extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTabChange;

  const _TopHeader({required this.tab, required this.onTabChange});

  static const _tabs = ['For You', 'Live', 'Movies', 'Series'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.black.withOpacity(0.85),
      child: Row(
        children: [
          // Logo
          RichText(
            text: const TextSpan(children: [
              TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -1)),
              TextSpan(text: '⁹', style: TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 32),
          // Tabs
          ..._tabs.asMap().entries.map((e) => _TabItem(
            label: e.value,
            selected: tab == e.key,
            onTap: () => onTabChange(e.key),
          )),
          const Spacer(),
          // Icons
          _IconBtn(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.settings, onTap: () {}),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({required this.label, required this.selected, required this.onTap});

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
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
            color: _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.white : Colors.white54,
              fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 20),
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
  final List<LiveChannel> channels;
  final XtreamCredentials creds;
  final int tab;
  final ValueChanged<int> onTabChange;

  const _ForYouTab({
    required this.vods, required this.series,
    required this.vodCats, required this.seriesCats,
    required this.channels, required this.creds,
    required this.tab, required this.onTabChange,
  });

  @override
  State<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<_ForYouTab> {
  TmdbMovie? _heroTmdb;
  VodItem? _heroVod;
  bool _heroLoading = false;
  Timer? _debounce;
  List<WatchEntry> _history = [];
  int _heroIndex = 0;

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
    setState(() => _heroIndex = idx);
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
    final backdropUrl = _heroTmdb?.backdropUrl ?? _heroVod?.poster;
    final title = _heroTmdb?.title ?? _heroVod?.name ?? '';
    final overview = _heroTmdb?.overview ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          // =================== HERO SECTION ===================
          Stack(
            children: [
              // Background Image
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: backdropUrl != null
                    ? CachedNetworkImage(
                        key: ValueKey(backdropUrl),
                        imageUrl: backdropUrl,
                        width: double.infinity,
                        height: 420,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(height: 420, color: const Color(0xFF1A1A1A)),
                      )
                    : Container(key: const ValueKey('empty'), height: 420, color: const Color(0xFF1A1A1A)),
              ),

              // Dark Gradient Overlay (left → transparent)
              Container(
                height: 420,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // Bottom gradient
              Container(
                height: 420,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.0, 0.3],
                  ),
                ),
              ),

              // Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: logo + tabs
                    Row(children: [
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'mot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -1)),
                        TextSpan(text: '⁹', style: TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.bold)),
                      ])),
                      const SizedBox(width: 24),
                      ...[('For You', 0), ('Live', 1), ('Movies', 2), ('Series', 3)].map((t) =>
                        _TabItem(label: t.$1, selected: widget.tab == t.$2, onTap: () => widget.onTabChange(t.$2))
                      ),
                    ]),
                    // Right: icons
                    Row(children: [
                      _IconBtn(icon: Icons.search, onTap: () {}),
                      const SizedBox(width: 8),
                      _IconBtn(icon: Icons.settings_outlined, onTap: () {}),
                    ]),
                  ],
                ),
              ),

              // Hero Content (Title + Description + Button)
              Positioned(
                left: 24,
                bottom: 40,
                right: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(title),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_heroTmdb?.genres.isNotEmpty == true)
                        Text(
                          _heroTmdb!.genres.take(2).join(' · '),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      const SizedBox(height: 6),
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      if (overview.isNotEmpty)
                        Text(
                          overview,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),
                      if (_heroVod != null)
                        Row(children: [
                          _PlayBtn(
                            onTap: () => Navigator.push(context, _fadeRoute(
                              PlayerScreen(id: _heroVod!.id, title: _heroVod!.name, url: _heroVod!.streamUrl(widget.creds), poster: _heroVod!.poster),
                            )),
                          ),
                          const SizedBox(width: 10),
                          _InfoBtn(
                            onTap: () => Navigator.push(context, _fadeRoute(
                              MovieDetailScreen(item: _heroVod!, creds: widget.creds),
                            )),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),

              // Carousel dots (right bottom)
              Positioned(
                right: 20,
                bottom: 16,
                child: Row(
                  children: List.generate(5, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == (_heroIndex % 5) ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == (_heroIndex % 5) ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
              ),

              // Loading indicator
              if (_heroLoading)
                const Positioned(top: 60, right: 20,
                  child: SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(color: Color(0xFFE50914), strokeWidth: 1.5))),
            ],
          ),

          const SizedBox(height: 20),

          // =================== CONTINUE WATCHING ===================
          if (_history.isNotEmpty) ...[
            _SectionHeader(title: 'متابعة المشاهدة'),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _history.length,
                itemBuilder: (_, i) => _ContinueCard(entry: _history[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // =================== VOD ROWS ===================
          ...widget.vodCats.take(4).map((cat) {
            final items = widget.vods.where((v) => v.categoryId == cat.id).take(20).toList();
            if (items.isEmpty) return const SizedBox();
            return _ContentSection<VodItem>(
              title: cat.name,
              items: items,
              imageBuilder: (v) => v.poster,
              nameBuilder: (v) => v.name,
              onFocus: (v) => _onFocus(v),
              onTap: (v) => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: v, creds: widget.creds))),
            );
          }),

          // =================== SERIES ROWS ===================
          ...widget.seriesCats.take(3).map((cat) {
            final items = widget.series.where((s) => s.categoryId == cat.id).take(20).toList();
            if (items.isEmpty) return const SizedBox();
            return _ContentSection<SeriesItem>(
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
      ),
    );
  }
}

// =================== PLAY / INFO BUTTONS ===================

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
              borderRadius: const BorderRadius.all(Radius.circular(50)),
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
              borderRadius: const BorderRadius.all(Radius.circular(50)),
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

// =================== SECTION HEADER ===================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
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
            width: 170,
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _focused ? const Color(0xFFE50914) : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(fit: StackFit.expand, children: [
                widget.entry.poster != null
                    ? CachedNetworkImage(imageUrl: widget.entry.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A2A)))
                    : Container(color: const Color(0xFF2A2A2A)),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
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
      id: widget.entry.id,
      title: widget.entry.name,
      url: widget.entry.url,
      poster: widget.entry.poster,
      startPositionMs: widget.entry.positionMs,
    )));
  }
}

// =================== CONTENT SECTION ===================

class _ContentSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String? Function(T) imageBuilder;
  final String Function(T) nameBuilder;
  final void Function(T) onFocus;
  final void Function(T) onTap;

  const _ContentSection({
    required this.title, required this.items,
    required this.imageBuilder, required this.nameBuilder,
    required this.onFocus, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
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
        const SizedBox(height: 20),
      ],
    );
  }
}

// =================== POSTER CARD ===================

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

  static const double _w = 96.0;
  static const double _h = 140.0;

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
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _focused ? const Color(0xFFE50914) : Colors.transparent, width: 2),
              boxShadow: _focused ? [const BoxShadow(color: Colors.black87, blurRadius: 14, spreadRadius: 2)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(fit: StackFit.expand, children: [
                widget.image != null
                    ? CachedNetworkImage(imageUrl: widget.image!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    )),
                    child: Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
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
    child: const Icon(Icons.movie, color: Colors.white12, size: 24),
  );
}
