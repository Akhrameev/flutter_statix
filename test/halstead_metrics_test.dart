import 'dart:math';

import 'package:test/test.dart';

import '../bin/dart_metrics/maintainability_calculator.dart';

void main() {
  group('HalsteadMetrics', () {
    test('vocabulary is sum of distinct operators and operands', () {
      const m = HalsteadMetrics(
        distinctOperators: 5,
        distinctOperands: 8,
        totalOperators: 20,
        totalOperands: 30,
      );
      expect(m.vocabulary, equals(13));
    });

    test('length is sum of total operators and operands', () {
      const m = HalsteadMetrics(
        distinctOperators: 5,
        distinctOperands: 8,
        totalOperators: 20,
        totalOperands: 30,
      );
      expect(m.length, equals(50));
    });

    test('volume is N * log2(vocabulary)', () {
      const m = HalsteadMetrics(
        distinctOperators: 5,
        distinctOperands: 8,
        totalOperators: 20,
        totalOperands: 30,
      );
      final expected = 50 * (log(13) / ln2);
      expect(m.volume, closeTo(expected, 0.0001));
    });

    test('volume is 0.0 when vocabulary <= 1', () {
      const zeroVocab = HalsteadMetrics(
        distinctOperators: 0,
        distinctOperands: 0,
        totalOperators: 5,
        totalOperands: 5,
      );
      expect(zeroVocab.volume, equals(0.0));

      const singleVocab = HalsteadMetrics(
        distinctOperators: 1,
        distinctOperands: 0,
        totalOperators: 3,
        totalOperands: 0,
      );
      expect(singleVocab.volume, equals(0.0));
    });

    test('difficulty is (eta1/2) * (N2/eta2)', () {
      const m = HalsteadMetrics(
        distinctOperators: 10,
        distinctOperands: 8,
        totalOperators: 40,
        totalOperands: 24,
      );
      final expected = (10 / 2.0) * (24 / 8.0);
      expect(m.difficulty, closeTo(expected, 0.0001));
    });

    test('difficulty is 0.0 when distinctOperands is 0', () {
      const m = HalsteadMetrics(
        distinctOperators: 10,
        distinctOperands: 0,
        totalOperators: 40,
        totalOperands: 0,
      );
      expect(m.difficulty, equals(0.0));
    });

    test('effort is difficulty * volume', () {
      const m = HalsteadMetrics(
        distinctOperators: 6,
        distinctOperands: 4,
        totalOperators: 12,
        totalOperands: 8,
      );
      expect(m.effort, closeTo(m.difficulty * m.volume, 0.0001));
    });

    test('timeToProgram is effort / 18', () {
      const m = HalsteadMetrics(
        distinctOperators: 6,
        distinctOperands: 4,
        totalOperators: 12,
        totalOperands: 8,
      );
      expect(m.timeToProgram, closeTo(m.effort / 18.0, 0.0001));
    });

    test('deliveredBugs is volume / 3000', () {
      const m = HalsteadMetrics(
        distinctOperators: 6,
        distinctOperands: 4,
        totalOperators: 12,
        totalOperands: 8,
      );
      expect(m.deliveredBugs, closeTo(m.volume / 3000.0, 0.0001));
    });

    test('calculatedLength uses η1*log2(η1) + η2*log2(η2)', () {
      const m = HalsteadMetrics(
        distinctOperators: 4,
        distinctOperands: 8,
        totalOperators: 0,
        totalOperands: 0,
      );
      final expected =
          4 * log(4) / ln2 + 8 * log(8) / ln2;
      expect(m.calculatedLength, closeTo(expected, 0.0001));
    });

    test('calculatedLength is 0 when both distinct counts are 0', () {
      const m = HalsteadMetrics(
        distinctOperators: 0,
        distinctOperands: 0,
        totalOperators: 0,
        totalOperands: 0,
      );
      expect(m.calculatedLength, equals(0.0));
    });

    test('toString contains all four raw field values', () {
      const m = HalsteadMetrics(
        distinctOperators: 5,
        distinctOperands: 8,
        totalOperators: 20,
        totalOperands: 30,
      );
      final s = m.toString();
      expect(s, contains('5'));
      expect(s, contains('8'));
      expect(s, contains('20'));
      expect(s, contains('30'));
    });
  });
}
