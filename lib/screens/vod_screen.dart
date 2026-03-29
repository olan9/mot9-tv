import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/xtream_service.dart';
import '../utils/theme.dart';
import 'detail_screen.dart';

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
  int _selectedCat = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();
  late List<Category> _cats;

  @override
  void initState() {
    super.initState();
    _cats = [Category(id: '', name: 'الكل'), ...widget.categories];
  }

  List<VodItem> get _filtered {
    var items = widget.vods;
    final cat = _cats.isEmpty ? null : _cats[_selectedCat];
    if (cat != null && cat.id.isNotEmpty) {
      items = items.where((v) => v.categoryId == cat.id).toList();
    }
    if (_search.isNotEmpty) {
      items = items.where((v) => v.name.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 220,
          color: const Color(0xFF0D0D0D),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _cats.length,
                  itemBuilder: (_, i) => _SideItem(
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
          child: _filtered.isEmpty
              ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white38)))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _VodCard(
                    item: _filtered[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(item: _filtered[i], creds: widget.creds),
                    )),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SideItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SideItem({required this.label, required this.selected, required this.onTap});

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _focused ? (Matrix4.identity()..scale(1.06)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _focused ? Mot9Theme.accentRed : Colors.transparent, width: 2),
            boxShadow: _focused ? [const BoxShadow(color: Colors.black54, blurRadius: 16)] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.item.poster != null
                    ? CachedNetworkImage(imageUrl: widget.item.poster!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: Mot9Theme.cardColor, child: const Icon(Icons.movie, color: Colors.white24, size: 40)))
                    : Container(color: Mot9Theme.cardColor, child: const Icon(Icons.movie, color: Colors.white24, size: 40)),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    decoration: const BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        if (widget.item.year != null)
                          Text(widget.item.year!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                if (_focused)
                  Center(child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Mot9Theme.accentRed.withOpacity(0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
