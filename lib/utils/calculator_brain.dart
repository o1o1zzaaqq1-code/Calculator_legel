import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorBrain {
  String _expression = '';
  String _previewResult = '';
  bool _hasEvaluated = false;

  String get expression => _expression.isEmpty ? '0' : _expression;
  String get previewResult => _previewResult;
  bool get hasEvaluated => _hasEvaluated;

  String? get activeOperator {
    if (_expression.endsWith(' + ')) return '+';
    if (_expression.endsWith(' − ')) return '−';
    if (_expression.endsWith(' × ')) return '×';
    if (_expression.endsWith(' ÷ ')) return '÷';
    return null;
  }

  void reset() {
    _expression = '';
    _previewResult = '';
    _hasEvaluated = false;
  }

  void setExpression(String expr, {bool isResult = false}) {
    _expression = expr;
    _hasEvaluated = isResult;
    _updatePreview();
  }

  /// Appends a digit (0-9)
  void inputDigit(String digit) {
    if (_hasEvaluated) {
      _expression = '';
      _hasEvaluated = false;
    }

    if (_expression.isEmpty || _expression == '0') {
      _expression = digit;
    } else {
      // Check if last token is " 0" right after an operator
      if (_expression.endsWith('+ 0') ||
          _expression.endsWith('− 0') ||
          _expression.endsWith('× 0') ||
          _expression.endsWith('÷ 0')) {
        _expression = '${_expression.substring(0, _expression.length - 1)}$digit';
      } else {
        _expression += digit;
      }
    }
    _updatePreview();
  }

  /// Appends decimal point '.'
  void inputDecimal() {
    if (_hasEvaluated) {
      _expression = '0.';
      _hasEvaluated = false;
      _updatePreview();
      return;
    }

    if (_expression.isEmpty) {
      _expression = '0.';
      _updatePreview();
      return;
    }

    // Get current active number token
    final lastNumber = _getLastNumberToken();
    if (!lastNumber.contains('.')) {
      if (_isLastCharOperator()) {
        _expression += ' 0.';
      } else if (_expression.endsWith('(') || _expression.endsWith(' ')) {
        _expression += '0.';
      } else {
        _expression += '.';
      }
    }
    _updatePreview();
  }

  /// Handles binary operators: +, −, ×, ÷, ^
  void inputOperator(String op) {
    _hasEvaluated = false;

    if (_expression.isEmpty) {
      if (op == '−') {
        _expression = '−';
      } else {
        _expression = '0 $op ';
      }
      _updatePreview();
      return;
    }

    if (_expression == '−') {
      if (op != '−') {
        _expression = '';
      }
      return;
    }

    // If expression ends with an operator (e.g. "5 + "), replace it
    if (_expression.endsWith(' + ') ||
        _expression.endsWith(' − ') ||
        _expression.endsWith(' × ') ||
        _expression.endsWith(' ÷ ') ||
        _expression.endsWith(' ^ ')) {
      _expression = '${_expression.substring(0, _expression.length - 3)} $op ';
    } else if (_expression.endsWith('.')) {
      _expression = '${_expression.substring(0, _expression.length - 1)} $op ';
    } else {
      _expression += ' $op ';
    }
    _updatePreview();
  }

  /// Smart parenthesis toggle
  void inputParenthesis() {
    if (_hasEvaluated) {
      _expression = '(';
      _hasEvaluated = false;
      _updatePreview();
      return;
    }

    if (_expression.isEmpty || _expression == '0') {
      _expression = '(';
      _updatePreview();
      return;
    }

    final openCount = '('.allMatches(_expression).length;
    final closeCount = ')'.allMatches(_expression).length;

    // Check if we can close a parenthesis
    if (openCount > closeCount &&
        !_isLastCharOperator() &&
        !_expression.endsWith('(') &&
        !_expression.endsWith(' ')) {
      _expression += ')';
    } else {
      // Otherwise open parenthesis
      if (!_isLastCharOperator() &&
          !_expression.endsWith('(') &&
          !_expression.endsWith(' ')) {
        _expression += ' × (';
      } else {
        _expression += '(';
      }
    }
    _updatePreview();
  }

  /// Percentage calculation
  void inputPercent() {
    if (_expression.isEmpty || _isLastCharOperator()) return;

    // Evaluate current expression percent
    try {
      final sanitized = _sanitizeForEvaluation(_expression);
      final rawResult = _evaluateRaw(sanitized);
      if (rawResult != null) {
        final percentValue = rawResult / 100.0;
        _expression = _formatNumber(percentValue);
        _hasEvaluated = true;
        _previewResult = '';
      }
    } catch (_) {}
  }

  /// Toggle sign (+/-)
  void toggleSign() {
    if (_expression.isEmpty || _expression == '0') return;

    // If already evaluated, negate result
    if (_hasEvaluated) {
      if (_expression.startsWith('-')) {
        _expression = _expression.substring(1);
      } else {
        _expression = '-$_expression';
      }
      _updatePreview();
      return;
    }

    // Find the last number token in expression
    final tokens = _expression.split(' ');
    if (tokens.isEmpty) return;

    final lastToken = tokens.last;
    if (lastToken.isEmpty || _isOperator(lastToken)) return;

    if (lastToken.startsWith('(-') && lastToken.endsWith(')')) {
      // Remove (-...)
      final unwrapped = lastToken.substring(2, lastToken.length - 1);
      tokens[tokens.length - 1] = unwrapped;
    } else if (lastToken.startsWith('-')) {
      tokens[tokens.length - 1] = lastToken.substring(1);
    } else {
      tokens[tokens.length - 1] = '(-$lastToken)';
    }

    _expression = tokens.join(' ');
    _updatePreview();
  }

  /// Scientific function input: sin, cos, tan, ln, log, sqrt
  void inputFunction(String func) {
    if (_hasEvaluated) {
      _expression = '';
      _hasEvaluated = false;
    }

    String funcPrefix;
    switch (func) {
      case 'sin':
        funcPrefix = 'sin(';
        break;
      case 'cos':
        funcPrefix = 'cos(';
        break;
      case 'tan':
        funcPrefix = 'tan(';
        break;
      case 'ln':
        funcPrefix = 'ln(';
        break;
      case 'log':
        funcPrefix = 'log(';
        break;
      case '√':
        funcPrefix = 'sqrt(';
        break;
      case 'π':
        if (_expression.isEmpty || _expression == '0') {
          _expression = '${math.pi}';
        } else if (_isLastCharOperator()) {
          _expression += '${math.pi}';
        } else {
          _expression += ' × ${math.pi}';
        }
        _updatePreview();
        return;
      case 'e':
        if (_expression.isEmpty || _expression == '0') {
          _expression = '${math.e}';
        } else if (_isLastCharOperator()) {
          _expression += '${math.e}';
        } else {
          _expression += ' × ${math.e}';
        }
        _updatePreview();
        return;
      default:
        funcPrefix = '$func(';
    }

    if (_expression.isEmpty || _expression == '0') {
      _expression = funcPrefix;
    } else if (_isLastCharOperator() || _expression.endsWith('(')) {
      _expression += funcPrefix;
    } else {
      _expression += ' × $funcPrefix';
    }
    _updatePreview();
  }

  /// Backspace delete
  void deleteLast() {
    if (_hasEvaluated) {
      reset();
      return;
    }

    if (_expression.isEmpty) return;

    // If ends with spaced operator (e.g. " + "), remove 3 chars
    if (_expression.endsWith(' + ') ||
        _expression.endsWith(' − ') ||
        _expression.endsWith(' × ') ||
        _expression.endsWith(' ÷ ') ||
        _expression.endsWith(' ^ ')) {
      _expression = _expression.substring(0, _expression.length - 3);
    } else if (_expression.endsWith('sin(') ||
        _expression.endsWith('cos(') ||
        _expression.endsWith('tan(') ||
        _expression.endsWith('log(')) {
      _expression = _expression.substring(0, _expression.length - 4);
    } else if (_expression.endsWith('sqrt(')) {
      _expression = _expression.substring(0, _expression.length - 5);
    } else if (_expression.endsWith('ln(')) {
      _expression = _expression.substring(0, _expression.length - 3);
    } else {
      _expression = _expression.substring(0, _expression.length - 1);
    }

    if (_expression.isEmpty) {
      _previewResult = '';
    } else {
      _updatePreview();
    }
  }

  /// Evaluates the full expression on '=' tap
  String? evaluate() {
    if (_expression.isEmpty) return null;

    final sanitized = _sanitizeForEvaluation(_expression);
    try {
      final val = _evaluateRaw(sanitized);
      if (val == null) return null;

      if (val.isInfinite) {
        return 'Cannot divide by 0';
      }
      if (val.isNaN) {
        return 'Invalid format';
      }

      final formatted = _formatNumber(val);
      _previewResult = '';
      _hasEvaluated = true;
      final originalExpr = _expression;
      _expression = formatted;
      return originalExpr; // Return original expression for history logging
    } catch (e) {
      return null;
    }
  }

  void _updatePreview() {
    if (_expression.isEmpty || _hasEvaluated) {
      _previewResult = '';
      return;
    }

    // If expression ends with an operator, wait for next number before showing preview
    if (_isLastCharOperator()) {
      _previewResult = '';
      return;
    }

    // Only show live preview if there is an actual operation
    if (!_expression.contains(' + ') &&
        !_expression.contains(' − ') &&
        !_expression.contains(' × ') &&
        !_expression.contains(' ÷ ') &&
        !_expression.contains(' ^ ') &&
        !_expression.contains('(')) {
      _previewResult = '';
      return;
    }

    var textToEval = _expression;
    // Strip trailing operator or open parenthesis for live preview
    while (textToEval.endsWith(' + ') ||
        textToEval.endsWith(' − ') ||
        textToEval.endsWith(' × ') ||
        textToEval.endsWith(' ÷ ') ||
        textToEval.endsWith(' ^ ')) {
      textToEval = textToEval.substring(0, textToEval.length - 3);
    }

    if (textToEval.isEmpty) {
      _previewResult = '';
      return;
    }

    // Auto-balance parentheses for preview
    final openCount = '('.allMatches(textToEval).length;
    final closeCount = ')'.allMatches(textToEval).length;
    if (openCount > closeCount) {
      textToEval += ')' * (openCount - closeCount);
    }

    try {
      final sanitized = _sanitizeForEvaluation(textToEval);
      final val = _evaluateRaw(sanitized);
      if (val != null && !val.isInfinite && !val.isNaN) {
        _previewResult = _formatNumber(val);
      } else {
        _previewResult = '';
      }
    } catch (_) {
      _previewResult = '';
    }
  }

  double? _evaluateRaw(String mathExpr) {
    try {
      final parser = ShuntingYardParser();
      final exp = parser.parse(mathExpr);
      final cm = ContextModel();
      final num val = RealEvaluator(cm).evaluate(exp);
      return val.toDouble();
    } catch (_) {
      return null;
    }
  }

  String _sanitizeForEvaluation(String expr) {
    var s = expr;
    // Replace visual operators with math expressions operators
    s = s.replaceAll('−', '-');
    s = s.replaceAll('×', '*');
    s = s.replaceAll('÷', '/');
    s = s.replaceAll('√', 'sqrt');

    // Auto-close open parentheses
    final openCount = '('.allMatches(s).length;
    final closeCount = ')'.allMatches(s).length;
    if (openCount > closeCount) {
      s += ')' * (openCount - closeCount);
    }

    return s;
  }

  String _formatNumber(double val) {
    if (val.isNaN) return 'Error';
    if (val.isInfinite) return val > 0 ? 'Infinity' : '-Infinity';

    // If within standard range (under 1 trillion and above 1e-6)
    if (val.abs() < 1e12 && (val == 0 || val.abs() >= 1e-6)) {
      // If effectively an integer
      if ((val - val.roundToDouble()).abs() < 1e-9) {
        final formatter = NumberFormat('#,###');
        return formatter.format(val.round());
      }

      // If decimal, up to 8 decimal places without trailing zeros
      final formatter = NumberFormat('#,##0.########');
      return formatter.format(val);
    }

    // For astronomical numbers, clean scientific format
    return val.toStringAsPrecision(6).replaceAll('e+', ' × 10^').replaceAll('e-', ' × 10^-');
  }

  String _getLastNumberToken() {
    final tokens = _expression.split(' ');
    if (tokens.isEmpty) return '';
    return tokens.last;
  }

  bool _isLastCharOperator() {
    return _expression.endsWith(' + ') ||
        _expression.endsWith(' − ') ||
        _expression.endsWith(' × ') ||
        _expression.endsWith(' ÷ ') ||
        _expression.endsWith(' ^ ') ||
        _expression.endsWith(' ');
  }

  bool _isOperator(String token) {
    return token == '+' ||
        token == '−' ||
        token == '-' ||
        token == '×' ||
        token == '*' ||
        token == '÷' ||
        token == '/' ||
        token == '^';
  }
}
