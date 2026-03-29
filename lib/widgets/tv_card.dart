import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';

/// بطاقة أفقية (landscape) مع AutomaticKeepAlive + RepaintBoundary
class TvCard extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onFocused;

  const TvCard({
    super.key,
    this.imageUrl,
    required this.name,
    required this.width,
    required this.height,
    required this.onTap,
    this.onFocused,
  });

  @override
  State<TvCard> createState() => _TvCardState();
}

class _TvCardState extends State<TvCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final hasFocus = _focus.hasFocus;
    if (_focused == hasFocus) return;
    setState(() => _focused = hasFocus);
    if (hasFocus && widget.onFocused != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.onFocused!());
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: Focus(
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
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            transform: _focused
                ? (Matrix4.identity()..scale(1.07))
                : Matrix4.identity(),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  widget.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Name overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _placeholder() => const ColoredBox(
    color: Mot9Theme.cardColor,
    child: Center(child: Icon(Icons.movie, color: Colors.white12, size: 24)),
  );
}

/// زر "المزيد" في آخر الصف
class TvMoreCard extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const TvMoreCard({super.key, required this.width, required this.height, required this.onTap});

  @override
  State<TvMoreCard> createState() => _TvMoreCardState();
}

class _TvMoreCardState extends State<TvMoreCard> {
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
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: _focused ? Colors.white12 : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? Colors.white38 : Colors.white12,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
              SizedBox(height: 6),
              Text('المزيد', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
