import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';
import '../widgets/side_nav.dart';
import '../widgets/content_row.dart';
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
                _logout();
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
        return _HomeTab(channels: _channels, vods: _vods, series: _series, vodCats: _vodCats, seriesCats: _seriesCats, creds: widget.creds);
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

class _HomeTab extends StatefulWidget {
  final List<LiveChannel> channels;
  final List<VodItem> vods;
  final List<SeriesItem> series;
  final List<Category> vodCats;
  final List<Category> seriesCats;
  final XtreamCredentials creds;

  const _HomeTab({required this.channels, required this.vods, required this.series, required this.vodCats, required this.seriesCats, required this.creds});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  TmdbMovie? _heroTmdb;
  VodItem? _heroVod;

  @override
  void initState() {
    super.initState();
    _loadHero();
  }

  Future<void> _loadHero() async {
    if (widget.vods.isEmpty) return;
    final idx = DateTime.now().second % widget.vods.length;
    final vod = widget.vods[idx];
    final tmdb = await TmdbService.searchMovie(vod.name);
    if (mounted) setState(() { _heroVod = vod; _heroTmdb = tmdb; });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildHero(context),
        const SizedBox(height: 24),
        if (widget.channels.isNotEmpty)
          ContentRow<LiveChannel>(
            title: '📡 البث المباشر',
            items: widget.channels.take(20).toList(),
            imageBuilder: (c) => c.logo,
            nameBuilder: (c) => c.name,
            isWide: true,
            onTap: (c) => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlayerScreen(title: c.name, url: c.streamUrl(widget.creds)),
            )),
          ),
        ...widget.vodCats.take(3).map((cat) {
          final items = widget.vods.where((v) => v.categoryId == cat.id).take(15).toList();
          if (items.isEmpty) return const SizedBox();
          return ContentRow<VodItem>(
            title: cat.name,
            items: items,
            imageBuilder: (v) => v.poster,
            nameBuilder: (v) => v.name,
            onTap: (v) => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MovieDetailScreen(item: v, creds: widget.creds),
            )),
          );
        }),
        ...widget.seriesCats.take(2).map((cat) {
          final items = widget.series.where((s) => s.categoryId == cat.id).take(15).toList();
          if (items.isEmpty) return const SizedBox();
          return ContentRow<SeriesItem>(
            title: cat.name,
            items: items,
            imageBuilder: (s) => s.cover,
            nameBuilder: (s) => s.name,
            onTap: (s) {},
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final backdropUrl = _heroTmdb?.backdropUrl ?? _heroVod?.poster;
    final title = _heroTmdb?.title ?? _heroVod?.name ?? '';
    final overview = _heroTmdb?.overview ?? '';
    final year = _heroTmdb?.year ?? '';
    final rating = _heroTmdb?.ratingStr ?? '';

    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropUrl != null)
            CachedNetworkImage(imageUrl: backdropUrl, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)))
          else
            Container(color: const Color(0xFF1A1A1A)),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [Colors.transparent, Color(0xBB000000), Color(0xEE000000)],
            stops: [0.3, 0.6, 1.0],
          ))),
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xFF141414)],
            stops: [0.6, 1.0],
          ))),
          Positioned(
            left: 48, bottom: 48, right: MediaQuery.of(context).size.width * 0.35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  if (year.isNotEmpty) ...[
                    Text(year, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                    const SizedBox(width: 12),
                  ],
                  if (rating.isNotEmpty) ...[
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                  ],
                ]),
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(overview, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 20),
                if (_heroVod != null)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(item: _heroVod!, creds: widget.creds),
                    )),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                        SizedBox(width: 8),
                        Text('تشغيل', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
