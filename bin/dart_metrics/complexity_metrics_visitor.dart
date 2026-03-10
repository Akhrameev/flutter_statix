import 'dart:math';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'function_complexity.dart';
import 'maintainability_calculator.dart';

class ComplexityMetricsVisitor extends RecursiveAstVisitor<void> {
  final List<FunctionComplexity> metrics = [];
  final String _content;
  final String _filePath;

  ComplexityMetricsVisitor(this._content, this._filePath);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _analyzeFunction(node.name.lexeme, node.functionExpression.body, node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _analyzeFunction(node.name.lexeme, node.body, node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final name = node.name?.lexeme ?? '(constructor)';
    _analyzeFunction(name, node.body, node);
    super.visitConstructorDeclaration(node);
  }

  void _analyzeFunction(String name, AstNode body, AstNode declaration) {
    try {
      final analyzer = FunctionBodyAnalyzer();
      body.accept(analyzer);

      final lineCount = _calculateLineCount(declaration);
      final codeSnippet = _extractCodeSnippet(declaration) ?? '';

      // Analyze Halstead metrics from the code snippet
      final halsteadMetrics = MaintainabilityCalculator.analyzeCode(codeSnippet);

      // Compute Maintainability Index using updated calculator
      final maintainabilityIndex = MaintainabilityCalculator.calculate(
        linesOfCode: lineCount,
        cyclomaticComplexity: analyzer.complexity,
        halsteadMetrics: halsteadMetrics,
      );

      metrics.add(FunctionComplexity(
        name: name,
        complexity: analyzer.complexity,
        nestingLevel: analyzer.maxNesting,
        lineCount: lineCount,
        returnCount: analyzer.returnCount,
        booleanExprCount: analyzer.booleanExprCount,
        switchCaseCount: analyzer.switchCaseCount,
        maintainabilityIndex: maintainabilityIndex,
        halsteadMetrics: halsteadMetrics,
        codeSnippet: codeSnippet,
      ));
    } catch (e) {
      print('⚠️  Error analyzing function $name in $_filePath: $e');
    }
  }


  int _calculateLineCount(AstNode node) {
    final startLine = _getLineNumber(node.offset);
    final endLine = _getLineNumber(node.end);
    return max(1, endLine - startLine + 1);
  }

  int _getLineNumber(int offset) {
    int line = 1;
    for (int i = 0; i < offset && i < _content.length; i++) {
      if (_content[i] == '\n') line++;
    }
    return line;
  }

  String? _extractCodeSnippet(AstNode node) {
    try {
      if (node.offset >= 0 && node.end <= _content.length) {
        return _content.substring(node.offset, node.end);
      }
    } catch (e) {
      print('⚠️  Could not extract code snippet: $e');
    }
    return null;
  }
}

class FunctionBodyAnalyzer extends RecursiveAstVisitor<void> {
  int complexity = 1;
  int maxNesting = 0;
  int _currentNesting = 0;
  int returnCount = 0;
  int booleanExprCount = 0;
  int switchCaseCount = 0;

  void _increaseComplexity() => complexity++;

  void _withNesting(void Function() callback) {
    _currentNesting++;
    maxNesting = max(maxNesting, _currentNesting);
    try {
      callback();
    } finally {
      _currentNesting--;
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    _increaseComplexity();
    _withNesting(() => super.visitIfStatement(node));
  }

  @override
  void visitForStatement(ForStatement node) {
    _increaseComplexity();
    _withNesting(() => super.visitForStatement(node));
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _increaseComplexity();
    _withNesting(() => super.visitWhileStatement(node));
  }

  @override
  void visitDoStatement(DoStatement node) {
    _increaseComplexity();
    _withNesting(() => super.visitDoStatement(node));
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _increaseComplexity();
    switchCaseCount += node.members.whereType<SwitchCase>().length;
    _withNesting(() => super.visitSwitchStatement(node));
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _increaseComplexity();
    super.visitConditionalExpression(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    _increaseComplexity();
    // Each catch clause adds complexity
    complexity += node.catchClauses.length;
    _withNesting(() => super.visitTryStatement(node));
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    returnCount++;
    super.visitReturnStatement(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '&&' || operator == '||') {
      booleanExprCount++;
      _increaseComplexity(); // Logical operators increase complexity
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '!') {
      booleanExprCount++;
    }
    super.visitPrefixExpression(node);
  }
}