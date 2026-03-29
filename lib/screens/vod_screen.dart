import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'detail_screen.dart';

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 200),
);

class VodScreen extends StatefulWidget {
  final XtreamService service;
  final XtreamCredentials creds;
  final List<VodItem> vods;
  final List<Category> categories;

  const VodScreen({super.key, required this.service, required this.creds, required this.vods, required this.categories});

  @override
  State<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends State<VodScreen> {
  final _catNotifier = ValueNotifier<int>(0);
  final _searchCtrl = TextEditingController();
  final _searchNotifier = ValueNotifier<String>('');
  late List<Category> _cats;

  @override
  void initState() {
    super.initState();
    _cats = [Category(id: '', name: 'الكل'), ...widget.categories];
    _searchCtrl.addListener(() => _searchNotifier.value = _searchCtrl.text);
  }

  @override
  void dispose() {
    _catNotifier.dispose();
    _searchNotifier.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VodItem> _filtered(int catIdx, String search) {
    var items = widget.vods;
    final cat = _cats[catIdx];
    if (cat.id.isNotEmpty) items = items.where((v) => v.categoryId == cat.id).toList();
    if (search.isNotEmpty) items = items.where((v) => v.name.toLowerCase().contains(search.toLowerCase())).toList();
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: 200,
          color: const Color(0xFF0D0D0D),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 16),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            Expanded(
              child: FocusTraversalGroup(
                policy: const WidgetOrderTraversalPolicy(),
                child: ValueListenableBuilder<int>(
                  valueListenable: _catNotifier,
                  builder: (_, sel, __) => ListView.builder(
                    itemCount: _cats.length,
                    itemExtent: 44,
                    itemBuilder: (_, i) => _CatItem(
                      label: _cats[i].name,
                      selected: sel == i,
                      onTap: () => _catNotifier.value = i,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        // Grid
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _catNotifier,
            builder: (_, sel, __) => ValueListenableBuilder<String>(
              valueListenable: _searchNotifier,
              builder: (_, search, __) {
                final items = _filtered(sel, search);
                if (items.isEmpty) return const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white38)));
                return FocusTraversalGroup(
                  policy: const WidgetOrderTraversalPolicy(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _VodCard(
                      item: items[i],
                      onTap: () => Navigator.push(context, _fadeRoute(MovieDetailScreen(item: items[i], creds: widget.creds))),
                    ),
                  ),
                );
              },
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
            border: Border(left: BorderSide(color: widget.selected ? Mot9Theme.accentRed : Colors.transparent, width: 3)),
          ),
          child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.selected ? Colors.white : (_focused ? Colors.white : Colors.white54),
                fontSize: 13,
                fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
              )),
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

class _VodCardState extends State<_VodCard> with AutomaticKeepAliveClientMixin {
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
            transform: _focused ? (Matrix4.identity()..scale(1.06)) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                widget.item.poster != null
                    ? CachedNetworkImage(imageUrl: widget.item.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(color: Mot9Theme.cardColor, child: Center(child: Icon(Icons.movie, color: Colors.white12, size: 32))))
                    : const ColoredBox(color: Mot9Theme.cardColor, child: Center(child: Icon(Icons.movie, color: Colors.white12, size: 32))),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                    decoration: const BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)],
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
