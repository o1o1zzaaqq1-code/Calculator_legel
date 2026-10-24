import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/calculation_item.dart';
import '../models/theme_palette.dart';
import '../services/history_service.dart';

class HistorySheet extends StatefulWidget {
  final PremiumPalette palette;
  final Function(String expression, String result) onSelectCalculation;

  const HistorySheet({
    super.key,
    required this.palette,
    required this.onSelectCalculation,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  List<CalculationItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await HistoryService.instance.getHistory();
    if (mounted) {
      setState(() {
        _items = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    HapticFeedback.lightImpact();
    await HistoryService.instance.deleteItem(id);
    _loadHistory();
  }

  Future<void> _clearAll() async {
    HapticFeedback.mediumImpact();
    await HistoryService.instance.clearHistory();
    if (mounted) {
      setState(() {
        _items = [];
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'History cleared',
            style: TextStyle(color: widget.palette.backgroundColor),
          ),
          backgroundColor: widget.palette.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: widget.palette.menuBackgroundColor, // Solid color, NO BORDER
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: widget.palette.secondaryTextColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: widget.palette.accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Calculation History',
                      style: TextStyle(
                        color: widget.palette.numTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_items.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      color: widget.palette.opButtonColor,
                      size: 18,
                    ),
                    label: Text(
                      'Clear',
                      style: TextStyle(
                        color: widget.palette.opButtonColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: widget.palette.accentColor,
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calculate_outlined,
                              size: 64,
                              color: widget.palette.secondaryTextColor
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No calculation history yet',
                              style: TextStyle(
                                color: widget.palette.secondaryTextColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final formattedTime =
                              DateFormat('MMM d, hh:mm a').format(item.timestamp);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: widget.palette.displayCardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onSelectCalculation(
                                      item.expression, item.result);
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.expression,
                                              style: TextStyle(
                                                color: widget
                                                    .palette.secondaryTextColor,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '= ${item.result}',
                                              style: TextStyle(
                                                color: widget
                                                    .palette.numTextColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: widget.palette
                                                    .secondaryTextColor
                                                    .withValues(alpha: 0.6),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: widget
                                              .palette.secondaryTextColor,
                                          size: 18,
                                        ),
                                        onPressed: () => _deleteItem(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
