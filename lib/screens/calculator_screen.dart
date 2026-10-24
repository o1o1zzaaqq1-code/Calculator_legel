import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_config.dart';
import '../models/theme_palette.dart';
import '../services/ad_service.dart';
import '../services/history_service.dart';
import '../services/supabase_service.dart';
import '../utils/calculator_brain.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/calc_button.dart';
import '../widgets/display_area.dart';
import '../widgets/dropdown_menu_actions.dart';
import '../widgets/history_sheet.dart';

class CalculatorScreen extends StatefulWidget {
  final PremiumPalette currentPalette;
  final Function(PremiumPalette) onPaletteChanged;

  const CalculatorScreen({
    super.key,
    required this.currentPalette,
    required this.onPaletteChanged,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with WidgetsBindingObserver {
  final CalculatorBrain _brain = CalculatorBrain();
  late final TextEditingController _expressionController;
  final FocusNode _displayFocusNode = FocusNode();
  bool _isScientific = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupabaseService.instance.configNotifier.addListener(_onRemoteConfigChanged);
    _expressionController = TextEditingController(text: '0');

    // Fetch latest remote config in background and dynamically update UI (ad position, etc.)
    SupabaseService.instance.fetchAppConfiguration().then((config) {
      if (mounted && config != null) {
        setState(() {});
      }
    });
  }

  void _onRemoteConfigChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SupabaseService.instance.configNotifier.removeListener(_onRemoteConfigChanged);
    _expressionController.dispose();
    _displayFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdService.instance.showAppOpenAdIfAvailable();
      // Re-fetch config on app resume to immediately apply remote Supabase changes
      SupabaseService.instance.fetchAppConfiguration().then((config) {
        if (mounted && config != null) {
          setState(() {});
        }
      });
    }
  }

  /// Inserts text at the current cursor / selection position
  void _insertAtCursor(String insertion, {bool isOperator = false}) {
    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    var end = _expressionController.selection.end;

    if (start < 0 || end < 0) {
      start = currentText.length;
      end = currentText.length;
    }

    if (start > end) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    // If evaluated, start new expression unless continuing with an operator
    if (_brain.hasEvaluated) {
      if (isOperator) {
        _brain.setExpression(currentText, isResult: false);
        start = currentText.length;
        end = currentText.length;
      } else {
        _expressionController.value = TextEditingValue(
          text: insertion,
          selection: TextSelection.collapsed(offset: insertion.length),
        );
        _brain.setExpression(insertion);
        setState(() {});
        return;
      }
    }

    final before = currentText.substring(0, start);
    final after = currentText.substring(end);

    String newText;
    int newCursor;

    if (currentText == '0' && start == 1 && end == 1 && !isOperator && insertion != '.') {
      newText = insertion + after;
      newCursor = insertion.length;
    } else if (isOperator) {
      // Replace consecutive operators if user taps another operator
      if (before.endsWith(' + ') ||
          before.endsWith(' − ') ||
          before.endsWith(' × ') ||
          before.endsWith(' ÷ ') ||
          before.endsWith(' ^ ')) {
        final trimmedBefore = before.substring(0, before.length - 3);
        newText = '$trimmedBefore$insertion$after';
        newCursor = trimmedBefore.length + insertion.length;
      } else if (before.endsWith('.')) {
        final trimmedBefore = before.substring(0, before.length - 1);
        newText = '$trimmedBefore$insertion$after';
        newCursor = trimmedBefore.length + insertion.length;
      } else {
        newText = before + insertion + after;
        newCursor = start + insertion.length;
      }
    } else {
      newText = before + insertion + after;
      newCursor = start + insertion.length;
    }

    _expressionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _brain.setExpression(newText);
    setState(() {});
  }

  void _onDigit(String digit) {
    _insertAtCursor(digit);
  }

  void _onDecimal() {
    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    if (start < 0) start = currentText.length;

    final before = currentText.substring(0, start);
    final lastSpace = before.lastIndexOf(' ');
    final activeNumStart = lastSpace == -1 ? 0 : lastSpace + 1;
    final currentNumBefore = before.substring(activeNumStart);

    if (currentNumBefore.contains('.')) return;

    if (before.isEmpty || before.endsWith(' ') || before.endsWith('(')) {
      _insertAtCursor('0.');
    } else {
      _insertAtCursor('.');
    }
  }

  void _onOperator(String op) {
    _insertAtCursor(' $op ', isOperator: true);
  }

  void _onParenthesis() {
    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    if (start < 0) start = currentText.length;

    final before = currentText.substring(0, start);
    final openCount = '('.allMatches(currentText).length;
    final closeCount = ')'.allMatches(currentText).length;

    if (openCount > closeCount &&
        !before.endsWith(' ') &&
        !before.endsWith('(')) {
      _insertAtCursor(')');
    } else {
      if (before.isNotEmpty &&
          !before.endsWith(' ') &&
          !before.endsWith('(')) {
        _insertAtCursor(' × (', isOperator: true);
      } else {
        _insertAtCursor('(');
      }
    }
  }

  void _onPercent() {
    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    if (start < 0) start = currentText.length;

    final before = currentText.substring(0, start);
    final after = currentText.substring(start);

    final lastSpace = before.lastIndexOf(' ');
    final activeNumStart = lastSpace == -1 ? 0 : lastSpace + 1;
    final currentNum = before.substring(activeNumStart);

    final val = double.tryParse(currentNum);
    if (val != null) {
      final percentVal = (val / 100.0).toString();
      final cleanVal = percentVal.endsWith('.0')
          ? percentVal.substring(0, percentVal.length - 2)
          : percentVal;
      final newBefore = before.substring(0, activeNumStart) + cleanVal;
      final newText = newBefore + after;
      _expressionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newBefore.length),
      );
      _brain.setExpression(newText);
      setState(() {});
    }
  }

  void _onToggleSign() {
    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    if (start < 0) start = currentText.length;

    final before = currentText.substring(0, start);
    final after = currentText.substring(start);

    final lastSpace = before.lastIndexOf(' ');
    final activeNumStart = lastSpace == -1 ? 0 : lastSpace + 1;
    final currentNum = before.substring(activeNumStart);

    if (currentNum.isEmpty) {
      _insertAtCursor('(-');
      return;
    }

    String toggledNum;
    if (currentNum.startsWith('(-') && currentNum.endsWith(')')) {
      toggledNum = currentNum.substring(2, currentNum.length - 1);
    } else if (currentNum.startsWith('-')) {
      toggledNum = currentNum.substring(1);
    } else {
      toggledNum = '(-$currentNum)';
    }

    final newBefore = before.substring(0, activeNumStart) + toggledNum;
    final newText = newBefore + after;
    _expressionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newBefore.length),
    );
    _brain.setExpression(newText);
    setState(() {});
  }

  void _onFunction(String func) {
    if (func == 'π') {
      _insertAtCursor('3.14159265');
    } else if (func == 'e') {
      _insertAtCursor('2.71828182');
    } else if (func == '√') {
      _insertAtCursor('sqrt(');
    } else {
      _insertAtCursor('$func(');
    }
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    _brain.reset();
    _expressionController.value = const TextEditingValue(
      text: '0',
      selection: TextSelection.collapsed(offset: 1),
    );
    setState(() {});
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    if (_brain.hasEvaluated) {
      _onClear();
      return;
    }

    final currentText = _expressionController.text;
    var start = _expressionController.selection.start;
    var end = _expressionController.selection.end;

    if (start < 0 || end < 0) {
      start = currentText.length;
      end = currentText.length;
    }

    if (start > end) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    if (start != end) {
      final newText = currentText.substring(0, start) + currentText.substring(end);
      final finalTxt = newText.isEmpty ? '0' : newText;
      final finalCursor = newText.isEmpty ? 1 : start;
      _expressionController.value = TextEditingValue(
        text: finalTxt,
        selection: TextSelection.collapsed(offset: finalCursor),
      );
      _brain.setExpression(finalTxt);
      setState(() {});
      return;
    }

    if (start == 0) return;

    final before = currentText.substring(0, start);
    final after = currentText.substring(end);

    String newBefore;
    if (before.endsWith(' + ') ||
        before.endsWith(' − ') ||
        before.endsWith(' × ') ||
        before.endsWith(' ÷ ') ||
        before.endsWith(' ^ ')) {
      newBefore = before.substring(0, before.length - 3);
    } else if (before.endsWith('sin(') ||
        before.endsWith('cos(') ||
        before.endsWith('tan(') ||
        before.endsWith('log(')) {
      newBefore = before.substring(0, before.length - 4);
    } else if (before.endsWith('sqrt(')) {
      newBefore = before.substring(0, before.length - 5);
    } else if (before.endsWith('ln(')) {
      newBefore = before.substring(0, before.length - 3);
    } else {
      newBefore = before.substring(0, before.length - 1);
    }

    final newText = newBefore + after;
    final finalTxt = newText.isEmpty ? '0' : newText;
    final finalCursor = newText.isEmpty ? 1 : newBefore.length;

    _expressionController.value = TextEditingValue(
      text: finalTxt,
      selection: TextSelection.collapsed(offset: finalCursor),
    );
    _brain.setExpression(finalTxt);
    setState(() {});
  }

  void _onEquals() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    final originalExpr = _expressionController.text;
    final evaluatedExpr = _brain.evaluate();

    if (evaluatedExpr != null) {
      final res = _brain.expression;
      _expressionController.value = TextEditingValue(
        text: res,
        selection: TextSelection.collapsed(offset: res.length),
      );
      HistoryService.instance.addCalculation(
        expression: originalExpr,
        result: res,
      );
    }
    setState(() {});
  }

  void _openHistory() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => HistorySheet(
        palette: widget.currentPalette,
        onSelectCalculation: (expr, res) {
          setState(() {
            _brain.setExpression(res, isResult: true);
            _expressionController.value = TextEditingValue(
              text: res,
              selection: TextSelection.collapsed(offset: res.length),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.currentPalette;
    final isBannerTop = AdService.instance.isBannerTop;
    debugPrint('CRITICAL_CHECK_BANNER_POS: isBannerTop=$isBannerTop, pos=${AdService.instance.bannerPosition}, rawPos=${AdService.instance.getAdConfig("banner")?.position}');
    debugPrint('CRITICAL_CONFIG_ADS: ${SupabaseService.instance.appConfig?.ads.map((a) => "${a.adType}:${a.position}").toList()}');

    return Scaffold(
      backgroundColor: palette.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Banner Ad (Remote-Controlled by Supabase position: 'top')
            if (isBannerTop)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: BannerAdWidget(
                  key: const ValueKey('top_banner_ad'),
                  palette: palette,
                ),
              ),

            // Top Navigation & Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CALCULATOR',
                        style: TextStyle(
                          color: palette.numTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Scientific Mode Toggle Button
                  IconButton(
                    tooltip: 'Scientific Mode',
                    icon: Icon(
                      _isScientific
                          ? Icons.functions_rounded
                          : Icons.science_outlined,
                      color: _isScientific
                          ? palette.accentColor
                          : palette.secondaryTextColor,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      SystemSound.play(SystemSoundType.click);
                      setState(() {
                        _isScientific = !_isScientific;
                      });
                    },
                  ),

                  // History Button
                  IconButton(
                    tooltip: 'History',
                    icon: Icon(
                      Icons.history_rounded,
                      color: palette.secondaryTextColor,
                    ),
                    onPressed: _openHistory,
                  ),

                  // 3-DOT OVERFLOW MENU (Dropdown)
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: palette.menuBackgroundColor,
                    ),
                    child: PopupMenuButton<AppButtonConfig>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: palette.numTextColor,
                      ),
                      color: palette.menuBackgroundColor,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide.none, // ZERO BORDER
                      ),
                      onSelected: (button) {
                        DropdownMenuActions.handleButtonAction(
                          context: context,
                          button: button,
                          palette: palette,
                          onHistoryCleared: () => setState(() {}),
                          onThemeSelected: widget.onPaletteChanged,
                        );
                      },
                      itemBuilder: (BuildContext context) {
                        final buttons = _getMenuButtons();
                        return buttons.map((button) {
                          return PopupMenuItem<AppButtonConfig>(
                            value: button,
                            child: Row(
                              children: [
                                DropdownMenuActions.buildButtonIcon(
                                  button,
                                  palette,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    button.title,
                                    style: TextStyle(
                                      color: palette.numTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (button.badgeText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: palette.accentColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      button.badgeText,
                                      style: TextStyle(
                                        color: palette.backgroundColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Display Area with Cursor Navigation and Inline Editing
            Expanded(
              flex: 3,
              child: DisplayArea(
                controller: _expressionController,
                focusNode: _displayFocusNode,
                previewResult: _brain.previewResult,
                palette: palette,
                onSwipeDelete: _onBackspace,
              ),
            ),

            // Scientific Row (Collapsible)
            if (_isScientific)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSciButton('sin', () => _onFunction('sin'), palette),
                        _buildSciButton('cos', () => _onFunction('cos'), palette),
                        _buildSciButton('tan', () => _onFunction('tan'), palette),
                        _buildSciButton('ln', () => _onFunction('ln'), palette),
                        _buildSciButton('log', () => _onFunction('log'), palette),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSciButton('√', () => _onFunction('√'), palette),
                        _buildSciButton('^', () => _onOperator('^'), palette),
                        _buildSciButton('π', () => _onFunction('π'), palette),
                        _buildSciButton('e', () => _onFunction('e'), palette),
                        _buildSciButton('(', () => _onParenthesis(), palette),
                      ],
                    ),
                  ],
                ),
              ),

            // Main Keypad Area
            Expanded(
              flex: _isScientific ? 5 : 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  children: [
                    // Row 1: AC/C, Backspace, %, ÷
                    Expanded(
                      child: Row(
                        children: [
                          CalcButton(
                            text: _expressionController.text == '0' ? 'AC' : 'C',
                            onTap: _onClear,
                            backgroundColor: palette.funcButtonColor,
                            textColor: palette.opButtonColor,
                            fontSize: 22,
                          ),
                          CalcButton(
                            text: '',
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                            onLongPress: _onClear,
                            backgroundColor: palette.funcButtonColor,
                            textColor: palette.funcTextColor,
                          ),
                          CalcButton(
                            text: '%',
                            onTap: _onPercent,
                            backgroundColor: palette.funcButtonColor,
                            textColor: palette.funcTextColor,
                            fontSize: 22,
                          ),
                          CalcButton(
                            text: '÷',
                            onTap: () => _onOperator('÷'),
                            backgroundColor: palette.opButtonColor,
                            textColor: palette.opTextColor,
                            fontSize: 28,
                            isHighlighted: _brain.activeOperator == '÷',
                          ),
                        ],
                      ),
                    ),

                    // Row 2: 7, 8, 9, ×
                    Expanded(
                      child: Row(
                        children: [
                          CalcButton(
                            text: '7',
                            onTap: () => _onDigit('7'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '8',
                            onTap: () => _onDigit('8'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '9',
                            onTap: () => _onDigit('9'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '×',
                            onTap: () => _onOperator('×'),
                            backgroundColor: palette.opButtonColor,
                            textColor: palette.opTextColor,
                            fontSize: 28,
                            isHighlighted: _brain.activeOperator == '×',
                          ),
                        ],
                      ),
                    ),

                    // Row 3: 4, 5, 6, −
                    Expanded(
                      child: Row(
                        children: [
                          CalcButton(
                            text: '4',
                            onTap: () => _onDigit('4'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '5',
                            onTap: () => _onDigit('5'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '6',
                            onTap: () => _onDigit('6'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '−',
                            onTap: () => _onOperator('−'),
                            backgroundColor: palette.opButtonColor,
                            textColor: palette.opTextColor,
                            fontSize: 28,
                            isHighlighted: _brain.activeOperator == '−',
                          ),
                        ],
                      ),
                    ),

                    // Row 4: 1, 2, 3, +
                    Expanded(
                      child: Row(
                        children: [
                          CalcButton(
                            text: '1',
                            onTap: () => _onDigit('1'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '2',
                            onTap: () => _onDigit('2'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '3',
                            onTap: () => _onDigit('3'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '+',
                            onTap: () => _onOperator('+'),
                            backgroundColor: palette.opButtonColor,
                            textColor: palette.opTextColor,
                            fontSize: 28,
                            isHighlighted: _brain.activeOperator == '+',
                          ),
                        ],
                      ),
                    ),

                    // Row 5: +/-, 0, ., =
                    Expanded(
                      child: Row(
                        children: [
                          CalcButton(
                            text: '+/-',
                            onTap: _onToggleSign,
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                            fontSize: 20,
                          ),
                          CalcButton(
                            text: '0',
                            onTap: () => _onDigit('0'),
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                          ),
                          CalcButton(
                            text: '.',
                            onTap: _onDecimal,
                            backgroundColor: palette.numButtonColor,
                            textColor: palette.numTextColor,
                            fontSize: 28,
                          ),
                          CalcButton(
                            text: '=',
                            onTap: _onEquals,
                            backgroundColor: palette.equalButtonColor,
                            textColor: palette.equalTextColor,
                            fontSize: 32,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Banner Ad (Remote-Controlled by Supabase position: 'bottom')
            if (!isBannerTop)
              BannerAdWidget(
                key: const ValueKey('bottom_banner_ad'),
                palette: palette,
              ),
          ],
        ),
      ),
    );
  }

  List<AppButtonConfig> _getMenuButtons() {
    final remote = SupabaseService.instance.visibleButtons;
    if (remote.isNotEmpty) return remote;

    return [
      AppButtonConfig(
        id: '1',
        buttonKey: 'privacy_policy',
        title: 'Privacy Policy',
        subtitle: '',
        icon: 'shield',
        actionType: 'policy',
        actionUrl: '',
        isVisible: true,
        sortOrder: 1,
        badgeText: '',
      ),
      AppButtonConfig(
        id: '2',
        buttonKey: 'share_app',
        title: 'Share',
        subtitle: '',
        icon: 'share',
        actionType: 'share',
        actionUrl: '',
        isVisible: true,
        sortOrder: 2,
        badgeText: '',
      ),
      AppButtonConfig(
        id: '3',
        buttonKey: 'rate_us',
        title: 'Rate Us',
        subtitle: '',
        icon: 'star',
        actionType: 'rate',
        actionUrl: '',
        isVisible: true,
        sortOrder: 3,
        badgeText: '',
      ),
      AppButtonConfig(
        id: '4',
        buttonKey: 'clear_history',
        title: 'Clear History',
        subtitle: '',
        icon: 'delete',
        actionType: 'clear_history',
        actionUrl: '',
        isVisible: true,
        sortOrder: 4,
        badgeText: '',
      ),
      AppButtonConfig(
        id: '5',
        buttonKey: 'theme',
        title: 'Theme',
        subtitle: '',
        icon: 'palette',
        actionType: 'theme',
        actionUrl: '',
        isVisible: true,
        sortOrder: 5,
        badgeText: '',
      ),
      AppButtonConfig(
        id: '6',
        buttonKey: 'feedback',
        title: 'Send Feedback',
        subtitle: '',
        icon: 'feedback',
        actionType: 'feedback',
        actionUrl: '',
        isVisible: true,
        sortOrder: 6,
        badgeText: '',
      ),
    ];
  }

  Widget _buildSciButton(
      String label, VoidCallback onTap, PremiumPalette palette) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: SizedBox(
          height: 38,
          child: Material(
            color: palette.funcButtonColor, // Solid color, NO BORDER
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                SystemSound.play(SystemSoundType.click);
                onTap();
              },
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.funcTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
