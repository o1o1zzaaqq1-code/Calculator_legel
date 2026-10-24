import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/theme_palette.dart';

class DisplayArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String previewResult;
  final PremiumPalette palette;
  final VoidCallback? onSwipeDelete;

  const DisplayArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.previewResult,
    required this.palette,
    this.onSwipeDelete,
  });

  @override
  State<DisplayArea> createState() => _DisplayAreaState();
}

class _DisplayAreaState extends State<DisplayArea> {
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void didUpdateWidget(covariant DisplayArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.text != widget.controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_verticalScrollController.hasClients) {
          _verticalScrollController.animateTo(
            _verticalScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    final textToCopy = widget.previewResult.isNotEmpty
        ? widget.previewResult
        : widget.controller.text;
    if (textToCopy.isEmpty || textToCopy == '0') return;

    Clipboard.setData(ClipboardData(text: textToCopy.replaceAll(',', '')));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied "$textToCopy" to clipboard',
          style: TextStyle(color: widget.palette.backgroundColor),
        ),
        backgroundColor: widget.palette.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _copyToClipboard,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 140) {
          widget.onSwipeDelete?.call();
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: widget.palette.displayCardColor, // Solid color, NO BORDER
          borderRadius: BorderRadius.circular(24),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompact = availableHeight < 110;
            final exprFontSize = isCompact
                ? 26.0
                : _getExpressionFontSize(widget.controller.text);
            final previewFontSize = isCompact ? 16.0 : 20.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Scrollable Multiline Wrapped TextField with Cursor
                Flexible(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.bottomRight,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        readOnly: true,
                        showCursor: true,
                        autofocus: true,
                        keyboardType: TextInputType.multiline,
                        enableInteractiveSelection: true,
                        cursorColor: widget.palette.accentColor,
                        cursorWidth: 3.0,
                        cursorRadius: const Radius.circular(2),
                        cursorHeight: exprFontSize * 1.15,
                        style: TextStyle(
                          color: widget.palette.numTextColor,
                          fontSize: exprFontSize,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: null, // Enables clean multiline auto-wrap
                        minLines: 1,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // Strictly NO border
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),

                // Real-time calculated preview result
                if (widget.previewResult.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '= ${widget.previewResult}',
                    style: TextStyle(
                      color: widget.palette.secondaryTextColor,
                      fontSize: previewFontSize,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  double _getExpressionFontSize(String text) {
    if (text.length > 35) return 22;
    if (text.length > 20) return 26;
    if (text.length > 12) return 32;
    return 38;
  }
}
