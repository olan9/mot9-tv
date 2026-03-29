import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';
import 'player_screen.dart';

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 250),
);

class MovieDetailScreen extends StatefulWidget {
  final VodItem item;
  final XtreamCredentials creds;

  const MovieDetailScreen({super.key, required this.item, required this.creds});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  TmdbMovie? _tmdb;
  bool _loading = true;
  final _playFocus = FocusNode();
  final _backFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _playFocus.addListener(() => setState(() {}));
    _backFocus.addListener(() => setState(() {}));
    _loadTmdb();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_playFocus);
    });
  }

  @override
  void dispose() {
    _playFocus.dispose();
    _backFocus.dispose();
    super.dispose();
  }

  Future<void> _loadTmdb() async {
    final result = await TmdbService.searchMovie(widget.item.name);
    if (mounted) setState(() { _tmdb = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mot9Theme.bgColor,
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: false,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack || event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackdrop(),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerRight, end: Alignment.centerLeft,
              colors: [Colors.transparent, Color(0xCC000000), Color(0xFF000000)],
              stops: [0.25, 0.55, 1.0],
            ))),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xFF141414)],
              stops: [0.5, 1.0],
            ))),
            Positioned(
              left: 56, top: 0, bottom: 0,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Focus(
                    focusNode: _backFocus,
                    onKeyEvent: (_, e) {
                      if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.select) {
                        Navigator.pop(context);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _backFocus.hasFocus ? Colors.white12 : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.arrow_back, color: Colors.white54, size: 16),
                          SizedBox(width: 5),
                          Text('رجوع', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _tmdb?.title ?? widget.item.name,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (_tmdb?.year.isNotEmpty == true) ...[
                      Text(_tmdb!.year, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (_tmdb != null) ...[
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 3),
                      Text(_tmdb!.ratingStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (_tmdb?.runtime != null) ...[
                      const Icon(Icons.access_time, color: Colors.white38, size: 12),
                      const SizedBox(width: 3),
                      Text('${_tmdb!.runtime} د', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ]),
                  if (_tmdb?.genres.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: _tmdb!.genres.take(3).map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                        child: Text(g, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      )).toList(),
                    ),
                  ],
                  if (_tmdb?.overview?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(_tmdb!.overview!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.6),
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Focus(
                    focusNode: _playFocus,
                    onKeyEvent: (_, e) {
                      if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.select) {
                        _play();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      onTap: _play,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                        decoration: BoxDecoration(
                          color: _playFocus.hasFocus ? Colors.white : Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: _playFocus.hasFocus
                              ? [const BoxShadow(color: Colors.white30, blurRadius: 16, spreadRadius: 1)]
                              : [],
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                          SizedBox(width: 6),
                          Text('تشغيل', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                  if (_tmdb?.cast.isNotEmpty == true) ...[
                    const SizedBox(height: 28),
                    const Text('الممثلون', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tmdb!.cast.length,
                        itemBuilder: (_, i) {
                          final c = _tmdb!.cast[i];
                          return Container(
                            width: 58,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(children: [
                              ClipOval(child: c.photoUrl != null
                                  ? CachedNetworkImage(imageUrl: c.photoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                                  : Container(width: 44, height: 44, color: Colors.white10, child: const Icon(Icons.person, color: Colors.white30, size: 20))),
                              const SizedBox(height: 4),
                              Text(c.name, style: const TextStyle(color: Colors.white54, fontSize: 9), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_loading)
              const Positioned(top: 32, right: 32,
                  child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Mot9Theme.accentRed, strokeWidth: 2))),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    final url = _tmdb?.backdropUrl ?? widget.item.poster;
    if (url == null) return Container(color: const Color(0xFF1A1A1A));
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)));
  }

  void _play() {
    Navigator.push(context, _fadeRoute(PlayerScreen(
      id: widget.item.id,
      title: widget.item.name,
      url: widget.item.streamUrl(widget.creds),
      poster: widget.item.poster,
    )));
  }
}
