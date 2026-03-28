import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class HeroBanner extends StatelessWidget {
  final LiveChannel channel;
  final XtreamCredentials creds;
  const HeroBanner({super.key, required this.channel, required this.creds});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (channel.logo != null)
            CachedNetworkImage(
              imageUrl: channel.logo!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
            )
          else
            Container(color: const Color(0xFF1A1A1A)),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.transparent, Color(0xCC000000), Color(0xEE000000)],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF141414)],
                stops: [0.6, 1.0],
              ),
            ),
          ),
          // Content
          Positioned(
            left: 60,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Mot9Theme.accentRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('بث مباشر', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(
                  channel.name,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8)]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _HeroBtn(icon: Icons.play_arrow, label: 'تشغيل', primary: true, onTap: () {}),
                    const SizedBox(width: 12),
                    _HeroBtn(icon: Icons.info_outline, label: 'معلومات', primary: false, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroBtn({required this.icon, required this.label, required this.primary, required this.onTap});

  @override
  State<_HeroBtn> createState() => _HeroBtnState();
}

class _HeroBtnState extends State<_HeroBtn> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_focused ? Colors.white : Colors.white)
                : (_focused ? Colors.white24 : Colors.white12),
            borderRadius: BorderRadius.circular(4),
            border: _focused && !widget.primary
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.primary ? Colors.black : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.primary ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
