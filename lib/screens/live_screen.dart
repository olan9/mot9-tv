import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'player_screen.dart';

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
  int _selectedCat = 0;
  late List<Category> _cats;

  @override
  void initState() {
    super.initState();
    _cats = [Category(id: '', name: 'الكل'), ...widget.categories];
  }

  List<LiveChannel> get _filtered {
    final cat = _cats.isEmpty ? null : _cats[_selectedCat];
    if (cat == null || cat.id.isEmpty) return widget.channels;
    return widget.channels.where((c) => c.categoryId == cat.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 220,
          color: const Color(0xFF0D0D0D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('الفئات', style: TextStyle(color: Mot9Theme.textSecondary, fontSize: 12, letterSpacing: 1.5)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _cats.length,
                  itemBuilder: (_, i) => _CatItem(
                    label: _cats[i].name,
                    selected: _selectedCat == i,
                    onTap: () => setState(() => _selectedCat = i),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _ChannelCard(
              channel: _filtered[i],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlayerScreen(title: _filtered[i].name, url: _filtered[i].streamUrl(widget.creds)),
              )),
            ),
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
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: widget.selected ? Mot9Theme.accentRed.withOpacity(0.15) : (_focused ? Colors.white10 : Colors.transparent),
            border: Border(left: BorderSide(color: widget.selected ? Mot9Theme.accentRed : Colors.transparent, width: 3)),
          ),
          child: Text(widget.label, style: TextStyle(
            color: widget.selected ? Colors.white : (_focused ? Colors.white : Colors.white60),
            fontSize: 14,
            fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
          )),
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

class _ChannelCardState extends State<_ChannelCard> {
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
          duration: const Duration(milliseconds: 120),
          transform: _focused ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: Mot9Theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            boxShadow: _focused ? [const BoxShadow(color: Colors.black54, blurRadius: 16)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Column(
              children: [
                Expanded(
                  child: widget.channel.logo != null
                      ? CachedNetworkImage(imageUrl: widget.channel.logo!, fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24, size: 32))
                      : const Icon(Icons.tv, color: Colors.white24, size: 32),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  color: _focused ? Mot9Theme.accentRed : const Color(0xFF1A1A1A),
                  child: Text(widget.channel.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
