import 'dart:convert';

class CalculationItem {
  final String id;
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationItem({
    required this.id,
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expression': expression,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculationItem.fromMap(Map<String, dynamic> map) {
    return CalculationItem(
      id: map['id'] ?? '',
      expression: map['expression'] ?? '',
      result: map['result'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CalculationItem.fromJson(String source) =>
      CalculationItem.fromMap(json.decode(source));
}
