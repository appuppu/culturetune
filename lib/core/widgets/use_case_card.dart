import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/tokens.dart';

/// 使いかた説明の1枚ぶん
class UseCaseItem {
  const UseCaseItem({
    required this.icon,
    required this.colorIndex,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final int colorIndex;
  final String title;
  final String body;
}

/// 使いかた説明をシールっぽいカードでペラペラめくれるカルーセル。
/// 空状態(シール帳/シール/カード/交換)で共用する。
class UseCaseCarousel extends StatefulWidget {
  const UseCaseCarousel({super.key, required this.items, this.height = 240});

  final List<UseCaseItem> items;
  final double height;

  @override
  State<UseCaseCarousel> createState() => _UseCaseCarouselState();
}

class _UseCaseCarouselState extends State<UseCaseCarousel> {
  final _controller = PageController(viewportFraction: 0.84);
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) =>
                _CarouselCard(item: widget.items[i], index: i),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.items.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _current
                      ? CTColors.primary
                      : CTColors.textSub.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.item, required this.index});

  final UseCaseItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color =
        CTColors.moodPalette[item.colorIndex % CTColors.moodPalette.length];
    return Transform.rotate(
          // シールを貼ったみたいに少しずつ傾ける
          angle: index.isEven ? -0.02 : 0.02,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CTColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 30, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: CTColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: (80 * index).ms)
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          curve: Curves.easeOutBack,
          duration: 400.ms,
        );
  }
}
