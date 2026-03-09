import 'dart:io';

import 'package:test/test.dart';

import '../bin/dart_metrics/function_complexity.dart';
import '../bin/dart_metrics/html_report_generator.dart';
import '../bin/dart_metrics/maintainability_calculator.dart';

void main() {
  group('HtmlReportGenerator.getMIBadge', () {
    test('returns EXCELLENT badge for mi >= 85', () {
      expect(HtmlReportGenerator.getMIBadge(100), contains('EXCELLENT'));
      expect(HtmlReportGenerator.getMIBadge(85), contains('EXCELLENT'));
    });

    test('returns GOOD badge for mi in [70, 85)', () {
      expect(HtmlReportGenerator.getMIBadge(84.9), contains('GOOD'));
      expect(HtmlReportGenerator.getMIBadge(70), contains('GOOD'));
    });

    test('returns MODERATE badge for mi in [50, 70)', () {
      expect(HtmlReportGenerator.getMIBadge(69.9), contains('MODERATE'));
      expect(HtmlReportGenerator.getMIBadge(50), contains('MODERATE'));
    });

    test('returns POOR badge for mi in [25, 50)', () {
      expect(HtmlReportGenerator.getMIBadge(49.9), contains('POOR'));
      expect(HtmlReportGenerator.getMIBadge(25), contains('POOR'));
    });

    test('returns LEGACY badge for mi < 25', () {
      expect(HtmlReportGenerator.getMIBadge(24.9), contains('LEGACY'));
      expect(HtmlReportGenerator.getMIBadge(0), contains('LEGACY'));
    });

    test('badge is an HTML span element', () {
      final badge = HtmlReportGenerator.getMIBadge(90);
      expect(badge, startsWith('<span'));
      expect(badge, endsWith('</span>'));
    });
  });

  group('HtmlReportGenerator.generateReport', () {
    const outputPath = 'flutter_statix/dart_metrics_report.html';

    setUp(() {
      Directory('flutter_statix').createSync(recursive: true);
    });

    tearDown(() {
      final f = File(outputPath);
      if (f.existsSync()) f.deleteSync();
    });

    test('empty file list writes a valid HTML shell', () async {
      await HtmlReportGenerator.generateReport([], {});
      final content = await File(outputPath).readAsString();
      expect(content, contains('<!DOCTYPE html>'));
      expect(content, contains('</html>'));
    });

    test('single file with one function writes function name in output',
        () async {
      final src = File('${Directory.systemTemp.path}/gen_test.dart')
        ..writeAsStringSync('void myFunc() {}');
      const fc = FunctionComplexity(
        name: 'myFunc',
        complexity: 1,
        nestingLevel: 0,
        lineCount: 5,
        returnCount: 1,
        booleanExprCount: 0,
        switchCaseCount: 0,
        maintainabilityIndex: 90.0,
        halsteadMetrics: HalsteadMetrics(
          distinctOperators: 3,
          distinctOperands: 4,
          totalOperators: 8,
          totalOperands: 12,
        ),
      );
      await HtmlReportGenerator.generateReport([src], {src: [fc]});
      final content = await File(outputPath).readAsString();
      expect(content, contains('myFunc'));
      expect(content, contains('EXCELLENT'));
      src.deleteSync();
    });

    test('low-MI function triggers recommendations section', () async {
      final src = File('${Directory.systemTemp.path}/gen_test2.dart')
        ..writeAsStringSync('void bad() {}');
      const fc = FunctionComplexity(
        name: 'bad',
        complexity: 15,
        nestingLevel: 4,
        lineCount: 80,
        returnCount: 5,
        booleanExprCount: 10,
        switchCaseCount: 3,
        maintainabilityIndex: 10.0,
        halsteadMetrics: HalsteadMetrics(
          distinctOperators: 20,
          distinctOperands: 30,
          totalOperators: 200,
          totalOperands: 300,
        ),
      );
      await HtmlReportGenerator.generateReport([src], {src: [fc]});
      final content = await File(outputPath).readAsString();
      expect(content, contains('Recommendations'));
      src.deleteSync();
    });
  });
}
