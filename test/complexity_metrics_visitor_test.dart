import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';

import '../bin/dart_metrics/complexity_metrics_visitor.dart';
import '../bin/dart_metrics/function_complexity.dart';

/// Parses [source] and returns the list of [FunctionComplexity] entries
/// produced by [ComplexityMetricsVisitor].
List<FunctionComplexity> analyzeSource(String source) {
  final result = parseString(content: source);
  final visitor = ComplexityMetricsVisitor(source, 'test.dart');
  result.unit.accept(visitor);
  return visitor.metrics;
}

void main() {
  // ---------------------------------------------------------------------------
  group('function detection', () {
    test('detects a single top-level function', () {
      final metrics = analyzeSource('int add(int a, int b) { return a + b; }');
      expect(metrics, hasLength(1));
      expect(metrics.first.name, equals('add'));
    });

    test('detects multiple top-level functions', () {
      const source = '''
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }
int mul(int a, int b) { return a * b; }
''';
      final metrics = analyzeSource(source);
      expect(metrics, hasLength(3));
      expect(metrics.map((m) => m.name), containsAll(['add', 'sub', 'mul']));
    });

    test('detects methods inside a class', () {
      const source = '''
class Calc {
  int add(int a, int b) { return a + b; }
  int sub(int a, int b) { return a - b; }
}
''';
      final metrics = analyzeSource(source);
      expect(metrics, hasLength(2));
      expect(metrics.map((m) => m.name), containsAll(['add', 'sub']));
    });

    test('detects unnamed constructor with name "(constructor)"', () {
      const source = '''
class Foo {
  final int x;
  Foo(this.x);
}
''';
      final metrics = analyzeSource(source);
      expect(metrics.any((m) => m.name == '(constructor)'), isTrue);
    });

    test('detects named constructor with its identifier as name', () {
      const source = '''
class Foo {
  final int x;
  Foo.create(this.x);
}
''';
      final metrics = analyzeSource(source);
      expect(metrics.any((m) => m.name == 'create'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('cyclomatic complexity', () {
    test('simple function with no branches has complexity 1', () {
      final metrics = analyzeSource('int f(int x) { return x; }');
      expect(metrics.first.complexity, equals(1));
    });

    test('if statement adds 1', () {
      const source = '''
void f(bool x) {
  if (x) { return; }
}
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('for loop adds 1', () {
      const source = '''
void f(List<int> xs) {
  for (int i = 0; i < xs.length; i++) { }
}
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('for-in loop adds 1', () {
      const source = '''
void f(List<int> xs) {
  for (final x in xs) { }
}
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('while loop adds 1', () {
      const source = '''
void f() {
  int i = 0;
  while (i < 10) { i++; }
}
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('do-while loop adds 1', () {
      const source = '''
void f() {
  int i = 0;
  do { i++; } while (i < 10);
}
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('switch statement adds 1 to complexity', () {
      const source = '''
void f(int x) {
  switch (x) {
    case 1: break;
    case 2: break;
    case 3: break;
  }
}
''';
      final m = analyzeSource(source).first;
      expect(m.complexity, equals(2)); // 1 base + 1 switch
      // Note: in the Dart 3 analyzer API, SwitchCase members are no longer
      // exposed as the SwitchCase subtype, so switchCaseCount stays 0.
      expect(m.switchCaseCount, equals(0));
    });

    test('ternary conditional expression adds 1', () {
      const source = 'int f(bool x) => x ? 1 : 0;';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('try with 1 catch adds 2 (try + 1 catch clause)', () {
      const source = '''
void f() {
  try {
    int x = 0;
  } catch (e) {
    return;
  }
}
''';
      // _increaseComplexity() → +1; complexity += catchClauses.length → +1
      expect(analyzeSource(source).first.complexity, equals(3));
    });

    test('try with 2 catch clauses adds 3', () {
      const source = '''
void f() {
  try {
    int x = 0;
  } on ArgumentError catch (e) {
    return;
  } catch (e) {
    return;
  }
}
''';
      expect(analyzeSource(source).first.complexity, equals(4)); // 1+1+2
    });

    test('&& operator adds 1 to complexity', () {
      const source = '''
bool f(bool a, bool b) { return a && b; }
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('|| operator adds 1 to complexity', () {
      const source = '''
bool f(bool a, bool b) { return a || b; }
''';
      expect(analyzeSource(source).first.complexity, equals(2));
    });

    test('! prefix does NOT add to complexity', () {
      const source = '''
bool f(bool a) { return !a; }
''';
      expect(analyzeSource(source).first.complexity, equals(1));
    });

    test('nested if statements accumulate complexity', () {
      const source = '''
void f(bool a, bool b) {
  if (a) {
    if (b) {
      return;
    }
  }
}
''';
      // 1 (base) + 1 (outer if) + 1 (inner if) = 3
      expect(analyzeSource(source).first.complexity, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  group('nesting level', () {
    test('flat function has maxNesting 0', () {
      const source = 'void f() { int x = 1; }';
      expect(analyzeSource(source).first.nestingLevel, equals(0));
    });

    test('single if gives maxNesting 1', () {
      const source = '''
void f(bool x) {
  if (x) { return; }
}
''';
      expect(analyzeSource(source).first.nestingLevel, equals(1));
    });

    test('for loop inside if gives maxNesting 2', () {
      const source = '''
void f(bool x, List<int> items) {
  if (x) {
    for (final item in items) { }
  }
}
''';
      expect(analyzeSource(source).first.nestingLevel, equals(2));
    });

    test('three-deep nesting gives maxNesting 3', () {
      const source = '''
void f(bool a, bool b, List<int> items) {
  if (a) {
    if (b) {
      for (final i in items) { }
    }
  }
}
''';
      expect(analyzeSource(source).first.nestingLevel, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  group('return counting', () {
    test('no explicit return gives returnCount 0', () {
      const source = 'void f() { int x = 1; }';
      expect(analyzeSource(source).first.returnCount, equals(0));
    });

    test('single return gives returnCount 1', () {
      const source = 'int f() { return 1; }';
      expect(analyzeSource(source).first.returnCount, equals(1));
    });

    test('multiple return paths give correct returnCount', () {
      const source = '''
int f(int x) {
  if (x > 0) return 1;
  if (x < 0) return -1;
  return 0;
}
''';
      expect(analyzeSource(source).first.returnCount, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  group('boolean expression counting', () {
    test('no boolean operators gives booleanExprCount 0', () {
      const source = 'int f(int x) { return x + 1; }';
      expect(analyzeSource(source).first.booleanExprCount, equals(0));
    });

    test('&& counts as one boolean expression', () {
      const source = 'bool f(bool a, bool b) { return a && b; }';
      expect(analyzeSource(source).first.booleanExprCount, equals(1));
    });

    test('|| counts as one boolean expression', () {
      const source = 'bool f(bool a, bool b) { return a || b; }';
      expect(analyzeSource(source).first.booleanExprCount, equals(1));
    });

    test('! counts as one boolean expression', () {
      const source = 'bool f(bool a) { return !a; }';
      expect(analyzeSource(source).first.booleanExprCount, equals(1));
    });

    test('combined &&, ||, ! each count once', () {
      // a && b || !c → 3 boolean expressions
      const source = 'bool f(bool a, bool b, bool c) { return a && b || !c; }';
      expect(analyzeSource(source).first.booleanExprCount, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  group('line count', () {
    test('single-line function has lineCount >= 1', () {
      const source = 'int f() { return 1; }';
      expect(analyzeSource(source).first.lineCount, greaterThanOrEqualTo(1));
    });

    test('multi-line function has correct lineCount', () {
      const source = 'int f() {\n  return 1;\n}';
      // Declaration spans 3 lines
      expect(analyzeSource(source).first.lineCount, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  group('metrics are independent per function', () {
    test('two functions have independent complexity values', () {
      const source = '''
int simple(int x) { return x; }
int complex(int x) {
  if (x > 0) {
    if (x > 100) return 2;
    return 1;
  }
  return 0;
}
''';
      final metrics = analyzeSource(source);
      expect(metrics, hasLength(2));
      final simple = metrics.firstWhere((m) => m.name == 'simple');
      final complex = metrics.firstWhere((m) => m.name == 'complex');
      expect(simple.complexity, equals(1));
      expect(complex.complexity, greaterThan(simple.complexity));
    });
  });
}
