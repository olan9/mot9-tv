import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../services/tmdb_service.dart';
import '../services/watch_history_service.dart';
import '../utils/theme.dart';
import '../widgets/top_nav.dart';
import '../widgets/tv_hero.dart';
import '../widgets/tv_row.dart';
import '../widgets/tv_card.dart';
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
  transitionDuration: const Duration(milliseconds: 200),
);

const int _rowLimit = 8;

class HomeScreen extends StatefulWidget {
  final XtreamCredentials creds;
  const HomeScreen({super.key, required this.creds});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ValueNotifier بدل setState للتاب — أداء أفضل
  final _tabNotifier = ValueNotifier<int>(0);
  late XtreamService _service;

  List<LiveChannel> _channels = [];
  List<VodItem> _vods = [];
  List<SeriesItem> _series = [];
  List<Category> _vodCats = [];
  List<Category> _seriesCats = [];
  List<Category> _liveCats = [];
  bool _loading = true;

  // Hero — ValueNotifier للأداء
  final _heroVodNotifier = ValueNotifier<VodItem?>(null);
  final _heroTmdbNotifier = ValueNotifier<TmdbMovie?>(null);
  final _heroLoadingNotifier = ValueNotifier<bool>(false);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _service = XtreamService(widget.creds);
    _loadAll();
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    _heroVodNotifier.dispose();
    _heroTmdbNotifier.dispose();
    _heroLoadingNotifier.dispose();
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
    if (!mounted) return;
    setState(() {
      _channels = results[0] as List<LiveChannel>;
      _vods = results[1] as List<VodItem>;
      _series = results[2] as List<SeriesItem>;
      _vodCats = results[3] as List<Category>;
      _seriesCats = results[4] as List<Category>;
      _liveCats = results[5] as List<Category>;
      _loading = false;
    });
    // تحميل الهيرو بعد البناء
    SchedulerBinding.instance.addPostFrameCallback((_) => _setInitialHero());
  }

  Future<void> _setInitialHero() async {
    if (_vods.isEmpty) return;
    final idx = DateTime.now().millisecond % _vods.length;
    await _loadHero(_vods[idx]);
  }

  Future<void> _loadHero(VodItem vod) async {
    if (_heroLoadingNotifier.value) return;
    _heroLoadingNotifier.value = true;
    final tmdb = await TmdbService.searchMovie(vod.name);
    if (!mounted) return;
    _heroVodNotifier.value = vod;
    _heroTmdbNotifier.value = tmdb;
    _heroLoadingNotifier.value = false;
  }

  void onPosterFocus(VodItem vod) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadHero(vod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mot9Theme.bgColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Mot9Theme.accentRed))
          : RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.goBack) {
                    Navigator.maybePop(context);
                  }
                }
              },
              child: Stack(
                children: [
                  // Page content — shifted down by header height
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _tabNotifier,
                      builder: (_, tab, __) => _buildPage(tab),
                    ),
                  ),
                  // Fixed TopNav
                  TopNav(
                    tabNotifier: _tabNotifier,
                    onSearch: () {},
                    onSettings: () {},
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPage(int tab) {
    switch (tab) {
      case 1:
        return LiveScreen(service: _service, creds: widget.creds, channels: _channels, categories: _liveCats);
      case 2:
        return VodScreen(service: _service, creds: widget.creds, vods: _vods, categories: _vodCats);
      case 3:
        return SeriesScreen(service: _service, creds: widget.creds, series: _series, categories: _seriesCats);
      default:
        return _ForYouPage(
          vods: _vods,
          series: _series,
          vodCats: _vodCats,
          seriesCats: _seriesCats,
          creds: widget.creds,
          heroVodNotifier: _heroVodNotifier,
          heroTmdbNotifier: _heroTmdbNotifier,
          heroLoadingNotifier: _heroLoadingNotifier,
          onPosterFocus: onPosterFocus,
        );
    }
  }
}

// =================== FOR YOU PAGE ===================

class _ForYouPage extends StatefulWidget {
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<Category> vodCats;
  final List<Category> seriesCats;
  final XtreamCredentials creds;
  final ValueNotifier<VodItem?> heroVodNotifier;
  final ValueNotifier<TmdbMovie?> heroTmdbNotifier;
  final ValueNotifier<bool> heroLoadingNotifier;
  final void Function(VodItem) onPosterFocus;

  const _ForYouPage({
    required this.vods, required this.series,
    required this.vodCats, required this.seriesCats,
    required this.creds,
    required this.heroVodNotifier,
    required this.heroTmdbNotifier,
    required this.heroLoadingNotifier,
    required this.onPosterFocus,
  });

  @override
  State<_ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<_ForYouPage> {
  List<WatchEntry> _history = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final h = await WatchHistoryService.getHistory();
    if (mounted) setState(() => _history = h);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Hero — يستخدم ValueListenableBuilder فقط يعيد بناء الهيرو
        ValueListenableBuilder<VodItem?>(
          valueListenable: widget.heroVodNotifier,
          builder: (_, vod, __) => ValueListenableBuilder<TmdbMovie?>(
            valueListenable: widget.heroTmdbNotifier,
            builder: (_, tmdb, __) => ValueListenableBuilder<bool>(
              valueListenable: widget.heroLoadingNotifier,
              builder: (_, loading, __) => TvHero(
                vod: vod,
                tmdb: tmdb,
                loading: loading,
                onPlay: vod == null ? null : () => Navigator.push(context, _fadeRoute(
                  PlayerScreen(id: vod.id, title: vod.name, url: vod.streamUrl(widget.creds), poster: vod.poster),
                )),
                onInfo: vod == null ? null : () => Navigator.push(context, _fadeRoute(
                  MovieDetailScreen(item: vod, creds: widget.creds),
                )),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Continue watching
        if (_history.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 10),
            child: Text('متابعة المشاهدة', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            height: 96,
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _history.length,
                itemExtent: 175,
                itemBuilder: (_, i) => _ContinueCard(entry: _history[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // VOD rows
        ...widget.vodCats.take(4).map((cat) {
          final all = widget.vods.where((v) => v.categoryId == cat.id).toList();
          if (all.isEmpty) return const SizedBox.shrink();
          final shown = all.take(_rowLimit).toList();
          return TvRow<VodItem>(
            key: ValueKey('vod_${cat.id}'),
            title: cat.name,
            items: shown,
            imageUrl: (v) => v.poster,
            name: (v) => v.name,
            onFocus: widget.onPosterFocus,
            onTap: (v) => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: v, creds: widget.creds))),
            hasMore: all.length > _rowLimit,
            onMore: () => Navigator.push(context, _fadeRoute(MoreVodScreen(title: cat.name, items: all, creds: widget.creds))),
          );
        }),

        // Series rows
        ...widget.seriesCats.take(3).map((cat) {
          final all = widget.series.where((s) => s.categoryId == cat.id).toList();
          if (all.isEmpty) return const SizedBox.shrink();
          final shown = all.take(_rowLimit).toList();
          return TvRow<SeriesItem>(
            key: ValueKey('series_${cat.id}'),
            title: cat.name,
            items: shown,
            imageUrl: (s) => s.cover,
            name: (s) => s.name,
            onFocus: (_) {},
            onTap: (_) {},
            hasMore: all.length > _rowLimit,
            onMore: () {},
          );
        }),

        const SizedBox(height: 40),
      ],
    );
  }
}

// =================== CONTINUE WATCHING CARD ===================

class _ContinueCard extends StatefulWidget {
  final WatchEntry entry;
  const _ContinueCard({required this.entry});

  @override
  State<_ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<_ContinueCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focused != _focus.hasFocus) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: Focus(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 165,
            margin: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
            transform: _focused ? (Matrix4.identity()..scale(1.06)) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? Mot9Theme.accentRed : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                widget.entry.poster != null
                    ? Image.network(widget.entry.poster!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Mot9Theme.cardColor))
                    : const ColoredBox(color: Mot9Theme.cardColor),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                      decoration: const BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xE5000000)],
                      )),
                      child: Text(widget.entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
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
