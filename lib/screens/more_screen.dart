import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../utils/theme.dart';
import 'detail_screen.dart';
import 'player_screen.dart';

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 220),
);

class MoreVodScreen extends StatelessWidget {
  final String title;
  final List<VodItem> items;
  final XtreamCredentials creds;

  const MoreVodScreen({super.key, required this.title, required this.items, required this.creds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(children: [
              _BackBtn(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _VodCard(
                item: items[i],
                onTap: () => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: items[i], creds: creds))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
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
        if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.select || e.logicalKey == LogicalKeyboardKey.goBack)) {
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _VodCard extends StatefulWidget {
  final VodItem item;
  final VoidCallback onTap;
  const _VodCard({required this.item, required this.onTap});

  @override
  State<_VodCard> createState() => _VodCardState();
}

class _VodCardState extends State<_VodCard> {
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                widget.item.poster != null
                    ? CachedNetworkImage(imageUrl: widget.item.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.movie, color: Colors.white12)))
                    : Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.movie, color: Colors.white12)),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    )),
                    child: Text(widget.item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
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
}
