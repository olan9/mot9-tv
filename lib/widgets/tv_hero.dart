import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';

/// Hero Banner ديناميكي يتغير مع المؤشر
class TvHero extends StatelessWidget {
  final VodItem? vod;
  final TmdbMovie? tmdb;
  final bool loading;
  final VoidCallback? onPlay;
  final VoidCallback? onInfo;

  const TvHero({
    super.key,
    this.vod,
    this.tmdb,
    this.loading = false,
    this.onPlay,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final backdropUrl = tmdb?.backdropUrl ?? vod?.poster;
    final title = tmdb?.title ?? vod?.name ?? '';
    final overview = tmdb?.overview ?? '';
    final year = tmdb?.year ?? '';
    final rating = tmdb?.ratingStr ?? '';
    final genre = tmdb?.genreStr ?? '';
    final runtime = tmdb?.runtimeStr ?? '';
    final logoUrl = tmdb?.logoUrl;

    return RepaintBoundary(
      child: SizedBox(
        height: 380,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop — AnimatedSwitcher للتبديل السلس
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: backdropUrl != null
                  ? CachedNetworkImage(
                      key: ValueKey(backdropUrl),
                      imageUrl: backdropUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1A)),
                    )
                  : const ColoredBox(key: ValueKey('empty'), color: Color(0xFF1A1A1A)),
            ),
            // Left gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xED0F0F0F), Color(0x990F0F0F), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0.0, 0.45, 0.72],
                ),
              ),
            ),
            // Bottom gradient
            const Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF0F0F0F), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 28,
              bottom: 28,
              right: MediaQuery.of(context).size.width * 0.38,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _HeroContent(
                  key: ValueKey(title),
                  title: title,
                  overview: overview,
                  year: year,
                  rating: rating,
                  genre: genre,
                  runtime: runtime,
                  logoUrl: logoUrl,
                  onPlay: onPlay,
                  onInfo: onInfo,
                ),
              ),
            ),
            // Loading dot
            if (loading)
              const Positioned(
                top: 16, right: 16,
                child: SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    color: Mot9Theme.accentRed,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final String title, overview, year, rating, genre, runtime;
  final String? logoUrl;
  final VoidCallback? onPlay;
  final VoidCallback? onInfo;

  const _HeroContent({
    super.key,
    required this.title, required this.overview,
    required this.year, required this.rating,
    required this.genre, required this.runtime,
    this.logoUrl, this.onPlay, this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo or title
        if (logoUrl != null)
          CachedNetworkImage(
            imageUrl: logoUrl!,
            height: 48,
            fit: BoxFit.fitHeight,
            errorWidget: (_, __, ___) => Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          )
        else if (title.isNotEmpty)
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 6),
        // Meta
        Row(children: [
          if (year.isNotEmpty) ...[
            Text(year, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(width: 10),
          ],
          if (rating.isNotEmpty) ...[
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 11),
            const SizedBox(width: 3),
            Text(rating, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(width: 10),
          ],
          if (runtime.isNotEmpty) ...[
            const Icon(Icons.access_time, color: Colors.white38, size: 11),
            const SizedBox(width: 3),
            Text(runtime, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ]),
        if (genre.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(genre, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
        if (overview.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            overview,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11, height: 1.5),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 14),
        if (onPlay != null)
          FocusTraversalGroup(
            policy: const WidgetOrderTraversalPolicy(),
            child: Row(children: [
              _HeroActionBtn(label: 'تشغيل', icon: Icons.play_arrow_rounded, primary: true, onTap: onPlay!),
              const SizedBox(width: 10),
              if (onInfo != null)
                _HeroActionBtn(label: 'تفاصيل', icon: Icons.info_outline_rounded, primary: false, onTap: onInfo!),
            ]),
          ),
      ],
    );
  }
}

class _HeroActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _HeroActionBtn({required this.label, required this.icon, required this.primary, required this.onTap});

  @override
  State<_HeroActionBtn> createState() => _HeroActionBtnState();
}

class _HeroActionBtnState extends State<_HeroActionBtn> {
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
                ? (_focused ? Colors.white : Colors.white.withOpacity(0.88))
                : (_focused ? Colors.white24 : Colors.white12),
            borderRadius: BorderRadius.circular(50),
            border: widget.primary ? null : Border.all(color: Colors.white30),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: widget.primary ? Colors.black : Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.primary ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
