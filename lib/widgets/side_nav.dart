import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

enum NavItem { home, movies, series, live, settings }

class SideNav extends StatelessWidget {
  final NavItem selected;
  final ValueChanged<NavItem> onSelect;

  const SideNav({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: RichText(
              text: const TextSpan(children: [
                TextSpan(text: 'm', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                TextSpan(text: '9', style: TextStyle(color: Mot9Theme.accentRed, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _NavBtn(icon: Icons.home_rounded, item: NavItem.home, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.movie_rounded, item: NavItem.movies, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.tv_rounded, item: NavItem.series, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.live_tv_rounded, item: NavItem.live, selected: selected, onSelect: onSelect),
          const Spacer(),
          _NavBtn(icon: Icons.settings_rounded, item: NavItem.settings, selected: selected, onSelect: onSelect),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon;
  final NavItem item;
  final NavItem selected;
  final ValueChanged<NavItem> onSelect;

  const _NavBtn({required this.icon, required this.item, required this.selected, required this.onSelect});

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  bool get _selected => widget.selected == widget.item;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
          widget.onSelect(widget.item);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onSelect(widget.item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _focused ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 22,
            color: _selected
                ? Mot9Theme.accentRed
                : _focused ? Colors.white
                : Colors.white38,
          ),
        ),
      ),
    );
  }
}
