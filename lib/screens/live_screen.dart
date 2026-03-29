import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'player_screen.dart';

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 200),
);

class LiveScreen extends StatefulWidget {
  final XtreamService service;
  final XtreamCredentials creds;
  final List<LiveChannel> channels;
  final List<Category> categories;

  const LiveScreen({super.key, required this.service, required this.creds, required this.channels, required this.categories});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _catNotifier = ValueNotifier<int>(0);
  late List<Category> _cats;

  @override
  void initState() {
    super.initState();
    _cats = [Category(id: '', name: 'الكل'), ...widget.categories];
  }

  @override
  void dispose() { _catNotifier.dispose(); super.dispose(); }

  List<LiveChannel> _filtered(int catIdx) {
    final cat = _cats[catIdx];
    if (cat.id.isEmpty) return widget.channels;
    return widget.channels.where((c) => c.categoryId == cat.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: 200,
          child: FocusTraversalGroup(
            policy: const WidgetOrderTraversalPolicy(),
            child: ValueListenableBuilder<int>(
              valueListenable: _catNotifier,
              builder: (_, sel, __) => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _cats.length,
                itemExtent: 46,
                itemBuilder: (_, i) => _CatItem(
                  label: _cats[i].name,
                  selected: sel == i,
                  onTap: () => _catNotifier.value = i,
                ),
              ),
            ),
          ),
        ),
        // Grid
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _catNotifier,
            builder: (_, sel, __) {
              final channels = _filtered(sel);
              return FocusTraversalGroup(
                policy: const WidgetOrderTraversalPolicy(),
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (_, i) => _ChannelCard(
                    channel: channels[i],
                    onTap: () => Navigator.push(context, _fadeRoute(
                      PlayerScreen(id: channels[i].id, title: channels[i].name, url: channels[i].streamUrl(widget.creds), poster: channels[i].logo, type: 'live'),
                    )),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatItem({required this.label, required this.selected, required this.onTap});

  @override
  State<_CatItem> createState() => _CatItemState();
}

class _CatItemState extends State<_CatItem> {
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
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected ? Mot9Theme.accentRed.withOpacity(0.12) : (_focused ? Colors.white10 : Colors.transparent),
            border: Border(left: BorderSide(
              color: widget.selected ? Mot9Theme.accentRed : Colors.transparent,
              width: 3,
            )),
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.selected ? Colors.white : (_focused ? Colors.white : Colors.white54),
              fontSize: 13,
              fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelCard extends StatefulWidget {
  final LiveChannel channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> with AutomaticKeepAliveClientMixin {
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
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: _focused ? (Matrix4.identity()..scale(1.08)) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: Mot9Theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Column(children: [
                Expanded(
                  child: widget.channel.logo != null
                      ? CachedNetworkImage(imageUrl: widget.channel.logo!, fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24, size: 28))
                      : const Icon(Icons.tv, color: Colors.white24, size: 28),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  color: _focused ? Mot9Theme.accentRed : const Color(0xFF1A1A1A),
                  child: Text(widget.channel.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
