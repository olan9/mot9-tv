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
      width: 80,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(children: [
                TextSpan(text: 'm', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                TextSpan(text: '9', style: TextStyle(color: Mot9Theme.accentRed, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          _NavBtn(icon: Icons.home_rounded, item: NavItem.home, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.movie_rounded, item: NavItem.movies, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.tv_rounded, item: NavItem.series, selected: selected, onSelect: onSelect),
          _NavBtn(icon: Icons.live_tv_rounded, item: NavItem.live, selected: selected, onSelect: onSelect),
          const Spacer(),
          _NavBtn(icon: Icons.settings_rounded, item: NavItem.settings, selected: selected, onSelect: onSelect),
          const SizedBox(height: 24),
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
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _selected
                ? Mot9Theme.accentRed.withOpacity(0.2)
                : _focused
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selected ? Mot9Theme.accentRed : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 24,
            color: _selected
                ? Mot9Theme.accentRed
                : _focused
                    ? Colors.white
                    : Colors.white54,
          ),
        ),
      ),
    );
  }
}
