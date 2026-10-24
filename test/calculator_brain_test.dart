import 'package:flutter_test/flutter_test.dart';
import 'package:premium_calculator/utils/calculator_brain.dart';

void main() {
  group('CalculatorBrain Unit Tests', () {
    late CalculatorBrain brain;

    setUp(() {
      brain = CalculatorBrain();
    });

    test('Initial state is 0 and empty preview', () {
      expect(brain.expression, '0');
      expect(brain.previewResult, '');
      expect(brain.hasEvaluated, false);
    });

    test('Basic addition: 7 + 8 = 15', () {
      brain.inputDigit('7');
      brain.inputOperator('+');
      brain.inputDigit('8');
      expect(brain.previewResult, '15');

      final expr = brain.evaluate();
      expect(expr, '7 + 8');
      expect(brain.expression, '15');
      expect(brain.hasEvaluated, true);
    });

    test('Operator precedence: 2 + 3 × 4 = 14', () {
      brain.inputDigit('2');
      brain.inputOperator('+');
      brain.inputDigit('3');
      brain.inputOperator('×');
      brain.inputDigit('4');
      expect(brain.previewResult, '14');

      brain.evaluate();
      expect(brain.expression, '14');
    });

    test('Decimal point accuracy: 0.1 + 0.2 = 0.3', () {
      brain.inputDigit('0');
      brain.inputDecimal();
      brain.inputDigit('1');
      brain.inputOperator('+');
      brain.inputDigit('0');
      brain.inputDecimal();
      brain.inputDigit('2');

      brain.evaluate();
      expect(brain.expression, '0.3');
    });

    test('Prevents multiple decimal points in same number', () {
      brain.inputDigit('5');
      brain.inputDecimal();
      brain.inputDigit('2');
      brain.inputDecimal(); // Should be ignored
      brain.inputDigit('5');

      expect(brain.expression, '5.25');
    });

    test('Division by zero handling', () {
      brain.inputDigit('9');
      brain.inputOperator('÷');
      brain.inputDigit('0');

      final res = brain.evaluate();
      expect(res, 'Cannot divide by 0');
    });

    test('Parentheses calculation: (5 + 3) × 2 = 16', () {
      brain.inputParenthesis();
      brain.inputDigit('5');
      brain.inputOperator('+');
      brain.inputDigit('3');
      brain.inputParenthesis();
      brain.inputOperator('×');
      brain.inputDigit('2');

      expect(brain.previewResult, '16');
      brain.evaluate();
      expect(brain.expression, '16');
    });

    test('Operator replacement: 5 + replaced by × then 4 = 20', () {
      brain.inputDigit('5');
      brain.inputOperator('+');
      brain.inputOperator('×'); // Replaces +
      brain.inputDigit('4');

      brain.evaluate();
      expect(brain.expression, '20');
    });

    test('Scientific square root: sqrt(25) = 5', () {
      brain.inputFunction('√');
      brain.inputDigit('2');
      brain.inputDigit('5');
      brain.inputParenthesis();

      brain.evaluate();
      expect(brain.expression, '5');
    });

    test('Delete/Backspace removes last token', () {
      brain.inputDigit('1');
      brain.inputDigit('2');
      brain.inputDigit('3');
      brain.deleteLast();

      expect(brain.expression, '12');
    });

    test('Reset clears all', () {
      brain.inputDigit('9');
      brain.inputOperator('+');
      brain.inputDigit('9');
      brain.reset();

      expect(brain.expression, '0');
      expect(brain.previewResult, '');
      expect(brain.hasEvaluated, false);
    });
  });
}
