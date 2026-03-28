import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';

class LiveScreen extends StatefulWidget {
  final XtreamService service;
  final XtreamCredentials creds;
  const LiveScreen({super.key, required this.service, required this.creds});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  List<Category> _categories = [];
  List<LiveChannel> _channels = [];
  int _selectedCat = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.service.getLiveCategories();
    final channels = await widget.service.getLiveStreams();
    if (mounted) {
      setState(() {
        _categories = [Category(id: '', name: 'الكل'), ...cats];
        _channels = channels;
        _loading = false;
      });
    }
  }

  List<LiveChannel> get _filtered {
    final cat = _categories.isEmpty ? null : _categories[_selectedCat];
    if (cat == null || cat.id.isEmpty) return _channels;
    return _channels.where((c) => c.categoryId == cat.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Mot9Theme.accentRed));

    return Row(
      children: [
        // Category sidebar
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
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) => _CatItem(
                    label: _categories[i].name,
                    selected: _selectedCat == i,
                    onTap: () => setState(() => _selectedCat = i),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Channel grid
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
            itemBuilder: (ctx, i) {
              final ch = _filtered[i];
              return _ChannelCard(
                channel: ch,
                onTap: () {
                  // TODO: Open player
                },
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
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
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
            border: Border(left: BorderSide(
              color: widget.selected ? Mot9Theme.accentRed : Colors.transparent,
              width: 3,
            )),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.white : (_focused ? Colors.white : Colors.white60),
              fontSize: 14,
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

class _ChannelCardState extends State<_ChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
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
                      ? CachedNetworkImage(
                          imageUrl: widget.channel.logo!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24, size: 32),
                        )
                      : const Icon(Icons.tv, color: Colors.white24, size: 32),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  color: _focused ? Mot9Theme.accentRed : const Color(0xFF1A1A1A),
                  child: Text(
                    widget.channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
