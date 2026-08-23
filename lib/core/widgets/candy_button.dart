import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// キャンディのようなグラデ+光沢+バウンスするピルボタン
class CandyButton extends StatefulWidget {
  const CandyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool expanded;

  @override
  State<CandyButton> createState() => _CandyButtonState();
}

class _CandyButtonState extends State<CandyButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final button = GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _scale = 0.95) : null,
      onTapCancel: enabled ? () => setState(() => _scale = 1) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _scale = 1);
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: enabled
                ? (widget.gradient ?? CTColors.primaryGradient)
                : const LinearGradient(
                    colors: [Color(0xFFE5DDE0), Color(0xFFD8CFD3)],
                  ),
            borderRadius: BorderRadius.circular(CTRadius.button),
            boxShadow: enabled ? ctCardShadow : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
