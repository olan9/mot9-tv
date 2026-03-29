import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// شريط تنقل علوي ثابت مع ValueNotifier للأداء
class TopNav extends StatelessWidget {
  final ValueNotifier<int> tabNotifier;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  static const _tabs = ['For You', 'Live', 'Movies', 'Series'];

  const TopNav({
    super.key,
    required this.tabNotifier,
    required this.onSearch,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.95), Colors.transparent],
        ),
      ),
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Row(
          children: [
            // Logo
            const Padding(
              padding: EdgeInsets.only(right: 24),
              child: _Logo(),
            ),
            // Tabs
            ValueListenableBuilder<int>(
              valueListenable: tabNotifier,
              builder: (_, tab, __) => Row(
                children: List.generate(
                  _tabs.length,
                  (i) => _NavTab(
                    label: _tabs[i],
                    selected: tab == i,
                    onTap: () => tabNotifier.value = i,
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Icons
            _NavIcon(icon: Icons.search, onTap: onSearch),
            const SizedBox(width: 8),
            _NavIcon(icon: Icons.settings_outlined, onTap: onSettings),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(children: [
        TextSpan(
          text: 'mot',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        TextSpan(
          text: '⁹',
          style: TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }
}

class _NavTab extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({required this.label, required this.selected, required this.onTap});

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
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
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white
                : _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.black : (_focused ? Colors.white : Colors.white54),
              fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavIcon({required this.icon, required this.onTap});

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _focused ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(widget.icon, color: _focused ? Colors.white : Colors.white60, size: 19),
        ),
      ),
    );
  }
}
