import 'package:flutter/material.dart';
import 'tv_card.dart';

/// صف أفقي محسّن مع ScrollController + auto-scroll + FocusTraversalGroup
class TvRow<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String? Function(T) imageUrl;
  final String Function(T) name;
  final void Function(T) onFocus;
  final void Function(T) onTap;
  final bool hasMore;
  final VoidCallback? onMore;

  // أبعاد البطاقة
  final double cardWidth;
  final double cardHeight;

  const TvRow({
    super.key,
    required this.title,
    required this.items,
    required this.imageUrl,
    required this.name,
    required this.onFocus,
    required this.onTap,
    this.hasMore = false,
    this.onMore,
    this.cardWidth = 160,
    this.cardHeight = 90,
  });

  @override
  State<TvRow<T>> createState() => _TvRowState<T>();
}

class _TvRowState<T> extends State<TvRow<T>> {
  final _scrollController = ScrollController();

  void _scrollToIndex(int index) {
    final offset = index * (widget.cardWidth + 10);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length + (widget.hasMore ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: widget.cardHeight + 16,
          child: FocusTraversalGroup(
            policy: const WidgetOrderTraversalPolicy(),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: itemCount,
              itemExtent: widget.cardWidth + 10, // تحسين ضخم للأداء
              itemBuilder: (_, i) {
                if (i == widget.items.length) {
                  return TvMoreCard(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    onTap: widget.onMore ?? () {},
                  );
                }
                return TvCard(
                  key: ValueKey('card_${widget.title}_$i'),
                  imageUrl: widget.imageUrl(widget.items[i]),
                  name: widget.name(widget.items[i]),
                  width: widget.cardWidth,
                  height: widget.cardHeight,
                  onFocused: () {
                    _scrollToIndex(i);
                    widget.onFocus(widget.items[i]);
                  },
                  onTap: () => widget.onTap(widget.items[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
