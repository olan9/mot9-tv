import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';

class ContentRow<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String? Function(T) imageBuilder;
  final String Function(T) nameBuilder;
  final void Function(T) onTap;

  const ContentRow({
    super.key,
    required this.title,
    required this.items,
    required this.imageBuilder,
    required this.nameBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 16, 48, 12),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 48),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _ContentCard(
              item: items[i],
              image: imageBuilder(items[i]),
              name: nameBuilder(items[i]),
              onTap: () => onTap(items[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ContentCard<T> extends StatefulWidget {
  final T item;
  final String? image;
  final String name;
  final VoidCallback onTap;

  const _ContentCard({super.key, required this.item, this.image, required this.name, required this.onTap});

  @override
  State<_ContentCard<T>> createState() => _ContentCardState<T>();
}

class _ContentCardState<T> extends State<_ContentCard<T>> {
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
          duration: const Duration(milliseconds: 150),
          width: _focused ? 170 : 155,
          height: _focused ? 170 : 155,
          margin: EdgeInsets.symmetric(horizontal: 6, vertical: _focused ? 0 : 8),
          transform: _focused ? (Matrix4.identity()..scale(1.08)) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _focused ? Mot9Theme.accentRed : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: _focused
                ? [const BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 4)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                widget.image != null
                    ? CachedNetworkImage(
                        imageUrl: widget.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _Placeholder(name: widget.name),
                      )
                    : _Placeholder(name: widget.name),
                // Bottom gradient + name
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Play icon on focus
                if (_focused)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Mot9Theme.accentRed.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
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

class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Mot9Theme.cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tv, color: Colors.white24, size: 36),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(name, maxLines: 2, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
