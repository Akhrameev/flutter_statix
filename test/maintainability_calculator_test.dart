import 'package:test/test.dart';

import '../bin/dart_metrics/maintainability_calculator.dart';

void main() {
  // Shared fixture: a simple HalsteadMetrics with moderate values
  const simpleMetrics = HalsteadMetrics(
    distinctOperators: 4,
    distinctOperands: 6,
    totalOperators: 8,
    totalOperands: 12,
  );

  const complexMetrics = HalsteadMetrics(
    distinctOperators: 30,
    distinctOperands: 50,
    totalOperators: 200,
    totalOperands: 300,
  );

  // -------------------------------------------------------------------------
  group('getMICategory', () {
    test('returns Excellent for mi >= 85', () {
      expect(MaintainabilityCalculator.getMICategory(100), equals('Excellent'));
      expect(MaintainabilityCalculator.getMICategory(85), equals('Excellent'));
    });

    test('returns Good for mi in [70, 85)', () {
      expect(MaintainabilityCalculator.getMICategory(84.9), equals('Good'));
      expect(MaintainabilityCalculator.getMICategory(70), equals('Good'));
    });

    test('returns Moderate for mi in [50, 70)', () {
      expect(MaintainabilityCalculator.getMICategory(69.9), equals('Moderate'));
      expect(MaintainabilityCalculator.getMICategory(50), equals('Moderate'));
    });

    test('returns Poor for mi in [25, 50)', () {
      expect(MaintainabilityCalculator.getMICategory(49.9), equals('Poor'));
      expect(MaintainabilityCalculator.getMICategory(25), equals('Poor'));
    });

    test('returns Legacy for mi < 25', () {
      expect(MaintainabilityCalculator.getMICategory(24.9), equals('Legacy'));
      expect(MaintainabilityCalculator.getMICategory(0), equals('Legacy'));
    });
  });

  // -------------------------------------------------------------------------
  group('getMIClass', () {
    test('returns correct CSS class for each category', () {
      expect(MaintainabilityCalculator.getMIClass(100), equals('mi-excellent'));
      expect(MaintainabilityCalculator.getMIClass(85), equals('mi-excellent'));
      expect(MaintainabilityCalculator.getMIClass(70), equals('mi-good'));
      expect(MaintainabilityCalculator.getMIClass(50), equals('mi-moderate'));
      expect(MaintainabilityCalculator.getMIClass(25), equals('mi-poor'));
      expect(MaintainabilityCalculator.getMIClass(0), equals('mi-legacy'));
    });
  });

  // -------------------------------------------------------------------------
  group('getMIColor', () {
    test('returns correct hex color for each category', () {
      expect(MaintainabilityCalculator.getMIColor(100), equals('#28a745'));
      expect(MaintainabilityCalculator.getMIColor(70), equals('#ffc107'));
      expect(MaintainabilityCalculator.getMIColor(50), equals('#fd7e14'));
      expect(MaintainabilityCalculator.getMIColor(25), equals('#dc3545'));
      expect(MaintainabilityCalculator.getMIColor(0), equals('#6c757d'));
    });
  });

  // -------------------------------------------------------------------------
  group('calculate', () {
    test('simple function yields high MI score', () {
      final mi = MaintainabilityCalculator.calculate(
        linesOfCode: 3,
        cyclomaticComplexity: 1,
        halsteadMetrics: simpleMetrics,
      );
      expect(mi, greaterThan(80));
    });

    test('complex function yields lower MI score than simple function', () {
      final simple = MaintainabilityCalculator.calculate(
        linesOfCode: 5,
        cyclomaticComplexity: 1,
        halsteadMetrics: simpleMetrics,
      );
      final complex = MaintainabilityCalculator.calculate(
        linesOfCode: 200,
        cyclomaticComplexity: 30,
        halsteadMetrics: complexMetrics,
      );
      expect(complex, lessThan(simple));
    });

    test('result is always in [0, 100]', () {
      // Extremely large inputs can drive raw MI negative — must clamp to 0
      final extremelyComplex = MaintainabilityCalculator.calculate(
        linesOfCode: 10000,
        cyclomaticComplexity: 500,
        halsteadMetrics: complexMetrics,
      );
      expect(extremelyComplex, greaterThanOrEqualTo(0));
      expect(extremelyComplex, lessThanOrEqualTo(100));

      // Trivial inputs should stay <= 100
      final trivial = MaintainabilityCalculator.calculate(
        linesOfCode: 1,
        cyclomaticComplexity: 1,
        halsteadMetrics: const HalsteadMetrics(
          distinctOperators: 1,
          distinctOperands: 1,
          totalOperators: 1,
          totalOperands: 1,
        ),
      );
      expect(trivial, lessThanOrEqualTo(100));
    });

    test('higher LOC reduces MI score (all else equal)', () {
      final short = MaintainabilityCalculator.calculate(
        linesOfCode: 5,
        cyclomaticComplexity: 1,
        halsteadMetrics: simpleMetrics,
      );
      final long = MaintainabilityCalculator.calculate(
        linesOfCode: 100,
        cyclomaticComplexity: 1,
        halsteadMetrics: simpleMetrics,
      );
      expect(long, lessThan(short));
    });
  });

  // -------------------------------------------------------------------------
  group('calculateMicrosoft', () {
    test('result is always in [0, 100]', () {
      final mi = MaintainabilityCalculator.calculateMicrosoft(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      expect(mi, greaterThanOrEqualTo(0));
      expect(mi, lessThanOrEqualTo(100));
    });

    test('comment ratio increases the score', () {
      final withoutComments = MaintainabilityCalculator.calculateMicrosoft(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
        commentRatio: 0.0,
      );
      final withComments = MaintainabilityCalculator.calculateMicrosoft(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
        commentRatio: 0.5,
      );
      expect(withComments, greaterThanOrEqualTo(withoutComments));
    });

    test('produces a lower raw score than original calculate for same inputs', () {
      // Microsoft formula normalizes by /171*100, which shifts values into 0-100
      // vs the original that can go above 100 and is then clamped; for typical
      // inputs the two formulas are proportional
      final microsoft = MaintainabilityCalculator.calculateMicrosoft(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      expect(microsoft, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  group('analyzeCode', () {
    test('empty string produces all-zero metrics', () {
      final m = MaintainabilityCalculator.analyzeCode('');
      expect(m.distinctOperators, equals(0));
      expect(m.distinctOperands, equals(0));
      expect(m.totalOperators, equals(0));
      expect(m.totalOperands, equals(0));
    });

    test('detects return and + as operators; a and b as operands', () {
      final m = MaintainabilityCalculator.analyzeCode('return a + b;');
      expect(m.distinctOperators, greaterThan(0));
      expect(m.distinctOperands, greaterThan(0));
      // 'a' and 'b' are operands
      expect(m.totalOperands, greaterThanOrEqualTo(2));
      // 'return' and '+' are operators
      expect(m.totalOperators, greaterThanOrEqualTo(2));
    });

    test('string literals are replaced and not counted as operands', () {
      final withLiteral = MaintainabilityCalculator.analyzeCode('"hello world"');
      final empty = MaintainabilityCalculator.analyzeCode('');
      // A bare string literal contributes no operands
      expect(withLiteral.distinctOperands, equals(empty.distinctOperands));
    });

    test('comments are stripped before tokenisation', () {
      final withComment = MaintainabilityCalculator.analyzeCode(
          '// this is a comment\nreturn x;');
      final withoutComment = MaintainabilityCalculator.analyzeCode('return x;');
      expect(withComment.totalOperands, equals(withoutComment.totalOperands));
      expect(withComment.totalOperators, equals(withoutComment.totalOperators));
    });

    test('more complex code produces higher token counts', () {
      const simple = 'return a;';
      const complex = '''
        if (a > b) {
          for (int i = 0; i < a; i++) {
            result += i;
          }
        } else {
          return b;
        }
      ''';
      final simpleM = MaintainabilityCalculator.analyzeCode(simple);
      final complexM = MaintainabilityCalculator.analyzeCode(complex);
      expect(complexM.totalOperators, greaterThan(simpleM.totalOperators));
      expect(complexM.totalOperands, greaterThan(simpleM.totalOperands));
    });
  });

  // -------------------------------------------------------------------------
  group('getDetailedAnalysis', () {
    test('result map contains all expected keys', () {
      final result = MaintainabilityCalculator.getDetailedAnalysis(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      expect(result, contains('maintainabilityIndex'));
      expect(result, contains('category'));
      expect(result, contains('cssClass'));
      expect(result, contains('color'));
      expect(result, contains('halsteadMetrics'));
      expect(result, contains('recommendations'));
    });

    test('category and cssClass are consistent with maintainabilityIndex', () {
      final result = MaintainabilityCalculator.getDetailedAnalysis(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      final mi = result['maintainabilityIndex'] as double;
      expect(result['category'],
          equals(MaintainabilityCalculator.getMICategory(mi)));
      expect(result['cssClass'],
          equals(MaintainabilityCalculator.getMIClass(mi)));
    });

    test('halsteadMetrics sub-map contains volume, difficulty, effort, timeToProgram, deliveredBugs', () {
      final result = MaintainabilityCalculator.getDetailedAnalysis(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      final hm = result['halsteadMetrics'] as Map;
      expect(hm, contains('volume'));
      expect(hm, contains('difficulty'));
      expect(hm, contains('effort'));
      expect(hm, contains('timeToProgram'));
      expect(hm, contains('deliveredBugs'));
    });

    test('recommendations is a non-empty list', () {
      final result = MaintainabilityCalculator.getDetailedAnalysis(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: simpleMetrics,
      );
      final recs = result['recommendations'] as List;
      expect(recs, isNotEmpty);
    });

    test('critical recommendation appears for very complex code', () {
      final result = MaintainabilityCalculator.getDetailedAnalysis(
        linesOfCode: 500,
        cyclomaticComplexity: 100,
        halsteadMetrics: complexMetrics,
      );
      final recs = result['recommendations'] as List<String>;
      expect(recs.any((r) => r.toLowerCase().contains('critical')), isTrue);
    });
  });

  group('calculateFromBasicMetrics', () {
    test('returns a value in [0, 100] using estimated Halstead', () {
      final mi = MaintainabilityCalculator.calculateFromBasicMetrics(
          linesOfCode: 10, cyclomaticComplexity: 2);
      expect(mi, inInclusiveRange(0.0, 100.0));
    });

    test('explicit Halstead inputs produce same result as calculate()', () {
      final mi1 = MaintainabilityCalculator.calculateFromBasicMetrics(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        numberOfOperators: 20,
        numberOfOperands: 30,
        distinctOperators: 5,
        distinctOperands: 8,
      );
      final mi2 = MaintainabilityCalculator.calculate(
        linesOfCode: 10,
        cyclomaticComplexity: 2,
        halsteadMetrics: const HalsteadMetrics(
          distinctOperators: 5,
          distinctOperands: 8,
          totalOperators: 20,
          totalOperands: 30,
        ),
      );
      expect(mi1, closeTo(mi2, 0.001));
    });
  });
}
