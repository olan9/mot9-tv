import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';
import 'player_screen.dart';

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
      FocusScope.of(context).requestFocus(_playFocus);
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
              (event.logicalKey == LogicalKeyboardKey.goBack ||
               event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
            _buildBackdrop(),
            // Gradient overlays
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.transparent, Color(0xDD000000), Color(0xFF000000)],
                  stops: [0.3, 0.6, 1.0],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF141414)],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 80,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Focus(
                    focusNode: _backFocus,
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                        Navigator.pop(context);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _backFocus.hasFocus ? Colors.white12 : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white60, size: 18),
                            SizedBox(width: 6),
                            Text('رجوع', style: TextStyle(color: Colors.white60, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    _tmdb?.title ?? widget.item.name,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Meta
                  Row(
                    children: [
                      if (_tmdb?.year.isNotEmpty == true) ...[
                        Text(_tmdb!.year, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                        const SizedBox(width: 16),
                      ],
                      if (_tmdb != null) ...[
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 4),
                        Text(_tmdb!.ratingStr, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                        const SizedBox(width: 16),
                      ],
                      if (_tmdb?.runtime != null) ...[
                        const Icon(Icons.access_time, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text('${_tmdb!.runtime} دقيقة', style: const TextStyle(color: Colors.white60, fontSize: 14)),
                      ],
                    ],
                  ),
                  if (_tmdb?.genres.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _tmdb!.genres.take(3).map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Overview
                  if (_tmdb?.overview?.isNotEmpty == true)
                    Text(
                      _tmdb!.overview!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 32),
                  // Play button
                  Focus(
                    focusNode: _playFocus,
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                        _play();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      onTap: _play,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: _playFocus.hasFocus ? Colors.white : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _playFocus.hasFocus
                              ? [const BoxShadow(color: Colors.white30, blurRadius: 20, spreadRadius: 2)]
                              : [],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                            SizedBox(width: 8),
                            Text('تشغيل', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Cast
                  if (_tmdb?.cast.isNotEmpty == true) ...[
                    const SizedBox(height: 40),
                    const Text('الممثلون', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tmdb!.cast.length,
                        itemBuilder: (_, i) {
                          final c = _tmdb!.cast[i];
                          return Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                ClipOval(
                                  child: c.photoUrl != null
                                      ? CachedNetworkImage(imageUrl: c.photoUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                      : Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.person, color: Colors.white38)),
                                ),
                                const SizedBox(height: 4),
                                Text(c.name, style: const TextStyle(color: Colors.white60, fontSize: 10), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Loading indicator
            if (_loading)
              const Positioned(
                top: 40, right: 40,
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Mot9Theme.accentRed, strokeWidth: 2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    final url = _tmdb?.backdropUrl ?? widget.item.poster;
    if (url == null) return Container(color: const Color(0xFF1A1A1A));
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)));
  }

  void _play() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(title: widget.item.name, url: widget.item.streamUrl(widget.creds)),
    ));
  }
}
