import 'dart:math';

/// Represents Halstead metrics for code complexity analysis
class HalsteadMetrics {
  final int distinctOperators;    // η1 (eta1)
  final int distinctOperands;     // η2 (eta2)
  final int totalOperators;       // N1
  final int totalOperands;        // N2

  const HalsteadMetrics({
    required this.distinctOperators,
    required this.distinctOperands,
    required this.totalOperators,
    required this.totalOperands,
  });

  /// Program vocabulary (η = η1 + η2)
  int get vocabulary => distinctOperators + distinctOperands;

  /// Program length (N = N1 + N2)
  int get length => totalOperators + totalOperands;

  /// Calculated program length (N̂ = η1 * log2(η1) + η2 * log2(η2))
  double get calculatedLength {
    double n1Log = distinctOperators > 0 ? distinctOperators * log(distinctOperators) / ln2 : 0;
    double n2Log = distinctOperands > 0 ? distinctOperands * log(distinctOperands) / ln2 : 0;
    return n1Log + n2Log;
  }

  /// Program volume (V = N * log2(η))
  double get volume {
    if (vocabulary <= 1) return 0.0;
    return length * (log(vocabulary) / ln2);
  }

  /// Program difficulty (D = (η1/2) * (N2/η2))
  double get difficulty {
    if (distinctOperands == 0) return 0.0;
    return (distinctOperators / 2.0) * (totalOperands / distinctOperands);
  }

  /// Program effort (E = D * V)
  double get effort => difficulty * volume;

  /// Time required to program (T = E / 18 seconds)
  double get timeToProgram => effort / 18.0;

  /// Number of delivered bugs (B = V / 3000)
  double get deliveredBugs => volume / 3000.0;

  @override
  String toString() {
    return 'HalsteadMetrics(η1: $distinctOperators, η2: $distinctOperands, '
        'N1: $totalOperators, N2: $totalOperands, V: ${volume.toStringAsFixed(2)})';
  }
}

/// Utility class for calculating standard Maintainability Index (MI)
/// Based on the original 1992 formula by Oman and Hagemeister
class MaintainabilityCalculator {
  /// Standard Maintainability Index thresholds
  static const double excellentThreshold = 85.0;
  static const double goodThreshold = 70.0;
  static const double moderateThreshold = 50.0;
  static const double poorThreshold = 25.0;

  /// Calculates the standard Maintainability Index
  ///
  /// Uses the original formula:
  /// MI = 171 - 5.2 * ln(HalsteadVolume) - 0.23 * CyclomaticComplexity - 16.2 * ln(LinesOfCode)
  ///
  /// Returns a score where:
  /// - 85+: Excellent maintainability (Green)
  /// - 70-84: Good maintainability (Yellow)
  /// - 50-69: Moderate maintainability (Orange)
  /// - 25-49: Poor maintainability (Red)
  /// - 0-24: Legacy code requiring immediate attention (Dark Red)
  static double calculate({
    required int linesOfCode,
    required int cyclomaticComplexity,
    required HalsteadMetrics halsteadMetrics,
  }) {
    // Ensure minimum values to avoid log(0) or negative logs
    final safeLinesOfCode = max(1, linesOfCode);
    final safeVolume = max(1.0, halsteadMetrics.volume);
    final safeCyclomaticComplexity = max(1, cyclomaticComplexity);

    // Original Maintainability Index formula
    double mi = 171.0 -
        5.2 * log(safeVolume) -
        0.23 * safeCyclomaticComplexity -
        16.2 * log(safeLinesOfCode);

    // Ensure MI is within reasonable bounds (0-100)
    return max(0.0, min(100.0, mi));
  }

  /// Microsoft's modified Maintainability Index with comment ratio
  /// MI = max(0, (171 - 5.2 * ln(V) - 0.23 * G - 16.2 * ln(LOC)) * 100 / 171)
  /// where comment ratio can be applied as a multiplier
  static double calculateMicrosoft({
    required int linesOfCode,
    required int cyclomaticComplexity,
    required HalsteadMetrics halsteadMetrics,
    double commentRatio = 0.0, // Percentage of comment lines (0.0 to 1.0)
  }) {
    final safeLinesOfCode = max(1, linesOfCode);
    final safeVolume = max(1.0, halsteadMetrics.volume);
    final safeCyclomaticComplexity = max(1, cyclomaticComplexity);

    // Microsoft's normalized formula
    double mi = (171.0 -
        5.2 * log(safeVolume) -
        0.23 * safeCyclomaticComplexity -
        16.2 * log(safeLinesOfCode)) * 100.0 / 171.0;

    // Apply comment ratio bonus (optional)
    if (commentRatio > 0) {
      mi = mi * (1.0 + commentRatio * 0.1); // 10% bonus per 10% comments
    }

    return max(0.0, min(100.0, mi));
  }

  /// Simplified calculation when you have basic code metrics
  /// This estimates Halstead metrics from available data
  static double calculateFromBasicMetrics({
    required int linesOfCode,
    required int cyclomaticComplexity,
    int? numberOfOperators,
    int? numberOfOperands,
    int? distinctOperators,
    int? distinctOperands,
  }) {
    // Estimate Halstead metrics if not provided
    final estimatedOperators = numberOfOperators ?? (linesOfCode * 2);
    final estimatedOperands = numberOfOperands ?? (linesOfCode * 3);
    final estimatedDistinctOperators = distinctOperators ??
        min(20, max(5, (cyclomaticComplexity * 2)));
    final estimatedDistinctOperands = distinctOperands ??
        min(30, max(8, (linesOfCode / 3).round()));

    final halsteadMetrics = HalsteadMetrics(
      distinctOperators: estimatedDistinctOperators,
      distinctOperands: estimatedDistinctOperands,
      totalOperators: estimatedOperators,
      totalOperands: estimatedOperands,
    );

    return calculate(
      linesOfCode: linesOfCode,
      cyclomaticComplexity: cyclomaticComplexity,
      halsteadMetrics: halsteadMetrics,
    );
  }

  /// Creates Halstead metrics from code tokens
  /// This is a simplified tokenizer - in practice, you'd use a proper lexer
  static HalsteadMetrics analyzeCode(String code) {
    // Dart operators (this is a simplified list)
    final operators = {
      '+', '-', '*', '/', '%', '++', '--', '==', '!=', '<', '>', '<=', '>=',
      '&&', '||', '!', '&', '|', '^', '~', '<<', '>>', '>>>',
      '=', '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '<<=', '>>=',
      '?', ':', '.', '?.', '..', '...', '=>', '(', ')', '[', ']', '{', '}',
      ';', ',', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'default',
      'break', 'continue', 'return', 'throw', 'try', 'catch', 'finally',
      'class', 'abstract', 'interface', 'mixin', 'enum', 'extension',
      'import', 'export', 'part', 'library', 'show', 'hide', 'as',
      'async', 'await', 'sync', 'yield', 'new', 'const', 'final', 'var',
      'static', 'late', 'required', 'void', 'dynamic', 'Function'
    };

    // Simple tokenization (this is very basic - use a proper lexer in production)
    final tokens = code
        .replaceAll(RegExp(r'//.*|/\*[\s\S]*?\*/'), '') // Remove comments
        .replaceAll(RegExp(r'"[^"]*"|' r"'[^']*'"), 'STRING') // Replace strings
        .split(RegExp(r'\s+|(?=[^\w])|(?<=[^\w])'))
        .where((token) => token.isNotEmpty)
        .toList();

    final operatorCounts = <String, int>{};
    final operandCounts = <String, int>{};

    for (final token in tokens) {
      if (operators.contains(token)) {
        operatorCounts[token] = (operatorCounts[token] ?? 0) + 1;
      } else if (token != 'STRING' && RegExp(r'^[a-zA-Z_]\w*$').hasMatch(token)) {
        operandCounts[token] = (operandCounts[token] ?? 0) + 1;
      }
    }

    return HalsteadMetrics(
      distinctOperators: operatorCounts.length,
      distinctOperands: operandCounts.length,
      totalOperators: operatorCounts.values.fold(0, (sum, count) => sum + count),
      totalOperands: operandCounts.values.fold(0, (sum, count) => sum + count),
    );
  }

  /// Returns the MI category as a string using standard thresholds
  static String getMICategory(double mi) {
    if (mi >= excellentThreshold) return 'Excellent';
    if (mi >= goodThreshold) return 'Good';
    if (mi >= moderateThreshold) return 'Moderate';
    if (mi >= poorThreshold) return 'Poor';
    return 'Legacy';
  }

  /// Returns the CSS class for the MI score using standard thresholds
  static String getMIClass(double mi) {
    if (mi >= excellentThreshold) return 'mi-excellent';
    if (mi >= goodThreshold) return 'mi-good';
    if (mi >= moderateThreshold) return 'mi-moderate';
    if (mi >= poorThreshold) return 'mi-poor';
    return 'mi-legacy';
  }

  /// Returns color code for the MI score
  static String getMIColor(double mi) {
    if (mi >= excellentThreshold) return '#28a745'; // Green
    if (mi >= goodThreshold) return '#ffc107';      // Yellow
    if (mi >= moderateThreshold) return '#fd7e14';  // Orange
    if (mi >= poorThreshold) return '#dc3545';      // Red
    return '#6c757d'; // Dark Red
  }

  /// Returns detailed analysis of the maintainability score
  static Map<String, dynamic> getDetailedAnalysis({
    required int linesOfCode,
    required int cyclomaticComplexity,
    required HalsteadMetrics halsteadMetrics,
  }) {
    final mi = calculate(
      linesOfCode: linesOfCode,
      cyclomaticComplexity: cyclomaticComplexity,
      halsteadMetrics: halsteadMetrics,
    );

    return {
      'maintainabilityIndex': mi,
      'category': getMICategory(mi),
      'cssClass': getMIClass(mi),
      'color': getMIColor(mi),
      'halsteadMetrics': {
        'volume': halsteadMetrics.volume,
        'difficulty': halsteadMetrics.difficulty,
        'effort': halsteadMetrics.effort,
        'timeToProgram': halsteadMetrics.timeToProgram,
        'deliveredBugs': halsteadMetrics.deliveredBugs,
      },
      'recommendations': _getRecommendations(mi, linesOfCode, cyclomaticComplexity, halsteadMetrics),
    };
  }

  static List<String> _getRecommendations(double mi, int loc, int cc, HalsteadMetrics hm) {
    final recommendations = <String>[];

    if (mi < poorThreshold) {
      recommendations.add('Critical: Immediate refactoring required');
    }

    if (loc > 50) {
      recommendations.add('Consider breaking down into smaller functions');
    }

    if (cc > 10) {
      recommendations.add('Reduce cyclomatic complexity by simplifying logic');
    }

    if (hm.volume > 1000) {
      recommendations.add('High Halstead volume - consider simplifying expressions');
    }

    if (hm.difficulty > 30) {
      recommendations.add('High difficulty score - improve variable naming and structure');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Code maintainability is acceptable');
    }

    return recommendations;
  }
}