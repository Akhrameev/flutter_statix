import 'package:test/test.dart';

import '../bin/dart_metrics/function_complexity.dart';
import '../bin/dart_metrics/maintainability_calculator.dart';

void main() {
  group('FunctionComplexity', () {
    const halstead = HalsteadMetrics(
      distinctOperators: 4,
      distinctOperands: 6,
      totalOperators: 10,
      totalOperands: 15,
    );

    test('toString includes name, complexity, and maintainabilityIndex', () {
      const fc = FunctionComplexity(
        name: 'myFunc',
        complexity: 3,
        nestingLevel: 1,
        lineCount: 10,
        returnCount: 2,
        booleanExprCount: 1,
        switchCaseCount: 0,
        maintainabilityIndex: 75.0,
        halsteadMetrics: halstead,
      );
      final s = fc.toString();
      expect(s, contains('myFunc'));
      expect(s, contains('3'));
      expect(s, contains('75.0'));
    });

    test('toString formats maintainabilityIndex to 1 decimal place', () {
      const fc = FunctionComplexity(
        name: 'f',
        complexity: 1,
        nestingLevel: 0,
        lineCount: 3,
        returnCount: 1,
        booleanExprCount: 0,
        switchCaseCount: 0,
        maintainabilityIndex: 91.2345,
        halsteadMetrics: halstead,
      );
      expect(fc.toString(), contains('91.2'));
      expect(fc.toString(), isNot(contains('91.23')));
    });
  });
}
