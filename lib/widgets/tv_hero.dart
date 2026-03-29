import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';

class TvHero extends StatelessWidget {
  final VodItem? vod;
  final TmdbMovie? tmdb;
  final bool loading;

  const TvHero({
    super.key,
    this.vod,
    this.tmdb,
    this.loading = false,
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
        height: 360,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
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
                child: Column(
                  key: ValueKey(title),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo أو اسم
                    if (logoUrl != null)
                      CachedNetworkImage(
                        imageUrl: logoUrl,
                        height: 48,
                        fit: BoxFit.fitHeight,
                        errorWidget: (_, __, ___) => Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (title.isNotEmpty)
                      Text(title,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // Meta row
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
                      Text(overview,
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11, height: 1.5),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Loading dot
            if (loading)
              const Positioned(
                top: 16, right: 16,
                child: SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(color: Mot9Theme.accentRed, strokeWidth: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
