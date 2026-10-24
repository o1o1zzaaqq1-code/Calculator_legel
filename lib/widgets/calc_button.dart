import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CalcButtonType {
  number,
  function,
  operator,
  equal,
}

class CalcButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final int flex;
  final double? height;
  final bool isHighlighted;

  const CalcButton({
    super.key,
    required this.text,
    this.icon,
    required this.onTap,
    this.onLongPress,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 24,
    this.flex = 1,
    this.height,
    this.isHighlighted = false,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() => _scale = 0.93);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.isHighlighted
        ? widget.textColor
        : widget.backgroundColor;
    final effectiveFg = widget.isHighlighted
        ? widget.backgroundColor
        : widget.textColor;

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: widget.height,
            child: Material(
              color: effectiveBg, // Pure solid color, NO border
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: widget.icon != null
                      ? Icon(
                          widget.icon,
                          color: effectiveFg,
                          size: 26,
                        )
                      : Text(
                          widget.text,
                          style: TextStyle(
                            color: effectiveFg,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
