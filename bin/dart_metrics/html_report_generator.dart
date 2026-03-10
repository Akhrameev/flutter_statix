import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'function_complexity.dart';
import 'maintainability_calculator.dart';

/// Generates HTML reports for code metrics analysis
class HtmlReportGenerator {
  static const String _outputFileName =
      'flutter_statix/dart_metrics_report.html';

  /// Generates and writes the HTML report
  static Future<void> generateReport(
    List<FileSystemEntity> files,
    Map<FileSystemEntity, List<FunctionComplexity>> fileMetrics,
  ) async {
    final buffer = StringBuffer();
    _writeHtmlHeader(buffer);

    int globalIndex = 0;

    for (final file in files) {
      final metrics = fileMetrics[file] ?? [];
      if (metrics.isNotEmpty) {
        _writeFileSection(buffer, file, metrics, globalIndex);
        globalIndex += metrics.length;
      }
    }

    _writeHtmlFooter(buffer);
    await _writeReport(buffer.toString());

    print('✅  | Dart Metrics HTML Report Generated: $_outputFileName');
  }

  static void _writeHtmlHeader(StringBuffer buffer) {
    buffer.writeln('''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dart Metrics Report</title>
    <style>
        :root {
            --color-excellent: #d4edda;
            --color-good: #d1ecf1;
            --color-moderate: #fff3cd;
            --color-poor: #f8d7da;
            --color-legacy: #e2e3e5;
            --border-color: #dee2e6;
            --text-color: #212529;
            --bg-color: #ffffff;
            --header-bg: #f8f9fa;
        }
        
        * { box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            padding: 20px;
            margin: 0;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
        }
        
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 30px;
        }
        
        h2 {
            color: #34495e;
            margin-top: 40px;
            margin-bottom: 20px;
        }
        
        .info-panel {
            background: var(--header-bg);
            padding: 20px;
            margin-bottom: 30px;
            border-left: 4px solid #007bff;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .info-panel h3 {
            margin-top: 0;
            color: #495057;
        }
        
        .info-panel ul {
            margin-bottom: 0;
        }
        
        .info-panel li {
            margin-bottom: 5px;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 40px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        th, td {
            border: 1px solid var(--border-color);
            padding: 12px 8px;
            text-align: left;
        }
        
        th {
            background-color: var(--header-bg);
            font-weight: 600;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        .cmi-excellent { background-color: var(--color-excellent); }
        .cmi-good { background-color: var(--color-good); }
        .cmi-moderate { background-color: var(--color-moderate); }
        .cmi-poor { background-color: var(--color-poor); }
        .cmi-legacy { background-color: var(--color-legacy); }
        
        .metric-badge {
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: bold;
  font-size: 12px;
  color: #fff;
}

.excellent-mi {
  background-color: #28a745; /* green */
}

.good-mi {
  background-color: #5cb85c; /* light green */
}

.moderate-mi {
  background-color: #f0ad4e; /* amber */
}

.poor-mi {
  background-color: #d9534f; /* red */
}

.legacy-mi {
  background-color: #6c757d; /* gray */
}

        
        .code-toggle {
            cursor: pointer;
            color: #007bff;
            text-decoration: underline;
            font-size: 0.9em;
            margin-left: 8px;
        }
        
        .code-toggle:hover {
            color: #0056b3;
        }
        
        .code-row {
            display: none;
        }
        
        .code-container {
            max-height: 400px;
            overflow-y: auto;
            border-radius: 4px;
        }
        
        pre {
            background: #f8f9fa;
            padding: 15px;
            margin: 0;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            line-height: 1.4;
            border-radius: 4px;
        }
        
        .file-stats {
            font-style: italic;
            color: #6c757d;
            margin-bottom: 10px;
        }
        
        .metric-badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 0.8em;
            font-weight: bold;
        }
        
        .mi-excellent { background-color: #88ba8b; color: black; }
        .mi-good { background-color: #dbecda; color: black; }
        .mi-moderate { background-color: #f2d883; color: black; }
        .mi-poor { background-color: #db8481; color: black; }
        .mi-legacy { background-color: #6c757d; color: white; }
        
        @media (max-width: 768px) {
            body { padding: 10px; }
            table { font-size: 0.9em; }
            th, td { padding: 8px 4px; }
        }
    </style>
</head>
<body>
    <h1>🔍 Dart Code Metrics Analysis Report</h1>
    
    <div class="info-panel">
        <h3>📏 Code Maintainability Index (CMI) Scale</h3>
        <ul>
            <li><strong>85-100:</strong> 🟢 Excellent maintainability - Well-structured, easy to maintain</li>
            <li><strong>70-84:</strong> 🔵 Good maintainability - Minor improvements possible</li>
            <li><strong>50-69:</strong> 🟡 Moderate maintainability - Consider refactoring</li>
            <li><strong>25-49:</strong> 🔴 Poor maintainability - Needs significant refactoring</li>
            <li><strong>0-24:</strong> ⚫ Legacy code - Requires immediate attention</li>
        </ul>
        <p><em>CMI combines lines of code, cyclomatic complexity, nesting depth, and other factors to assess code maintainability.</em></p>
    </div>
''');
  }

  static void _writeFileSection(
    StringBuffer buffer,
    FileSystemEntity file,
    List<FunctionComplexity> metrics,
    int startIndex,
  ) {
    final relativePath = path.relative(file.path);
    final fileStats = _calculateFileStats(metrics);

    buffer.writeln('<h2>📄 ${path.basename(file.path)}</h2>');
    buffer.writeln('<div class="file-stats">');
    buffer.writeln('Path: <code>$relativePath</code> | ');
    buffer.writeln('Functions: ${metrics.length} | ');
    buffer.writeln('Avg CMI: ${fileStats['avgCMI'].toStringAsFixed(1)} | ');
    buffer.writeln('Total Lines: ${fileStats['totalLines']}');
    buffer.writeln('</div>');

    buffer.writeln('<table>');
    buffer.writeln('''
        <tr>
            <th>Method Name</th>
            <th>Lines</th>
            <th>Nesting</th>
            <th>Complexity</th>
            <th>Returns</th>
            <th>Booleans</th>
            <th>Switch Cases</th>
            <th>CMI Score</th>
        </tr>
    ''');

    for (int i = 0; i < metrics.length; i++) {
      final metric = metrics[i];
      final cmiClass =
          MaintainabilityCalculator.getMIClass(metric.maintainabilityIndex);
      final complexityBadge = getMIBadge(metric.maintainabilityIndex);
      final globalIndex = startIndex + i;

      buffer.writeln('<tr class="$cmiClass">');
      buffer.writeln('<td>');
      buffer.writeln(metric.name);
      buffer.writeln(
          '<span class="code-toggle" onclick="toggleCode($globalIndex)">');
      buffer.writeln('View Code</span>');
      buffer.writeln('</td>');
      buffer.writeln('<td>${metric.lineCount}</td>');
      buffer.writeln('<td>${metric.nestingLevel}</td>');
      buffer.writeln('<td>$complexityBadge ${metric.complexity}</td>');
      buffer.writeln('<td>${metric.returnCount}</td>');
      buffer.writeln('<td>${metric.booleanExprCount}</td>');
      buffer.writeln('<td>${metric.switchCaseCount}</td>');
      buffer.writeln(
          '<td><strong>${metric.maintainabilityIndex.toStringAsFixed(1)}</strong></td>');
      buffer.writeln('</tr>');

      // Code snippet row
      final snippet = metric.codeSnippet ?? 'Code snippet not available';
      final escapedSnippet = htmlEscape.convert(snippet);

// Get detailed analysis
      final details = MaintainabilityCalculator.getDetailedAnalysis(
          linesOfCode: metric.lineCount,
          cyclomaticComplexity: metric.complexity,
          halsteadMetrics: metrics[i].halsteadMetrics);

// Extract analysis data
      final category = details['category'];
      final color = details['color'];
      final recommendations =
          (details['recommendations'] as List).map((r) => '<li>$r</li>').join();
      final halstead = details['halsteadMetrics'] as Map<String, dynamic>;

// Code snippet and details row
      buffer.writeln('<tr id="code-$globalIndex" class="code-row">');
      buffer.writeln('<td colspan="8">');
      buffer.writeln('<div class="code-container">');
      buffer.writeln('<pre><code>$escapedSnippet</code></pre>');
      buffer.writeln('</div>');

// Maintainability breakdown
      buffer.writeln(
          '<div style="margin-top: 10px; padding: 10px; border-left: 4px solid $color; background-color: #f1f1f1;">');
      buffer.writeln(
          '<strong>Maintainability: </strong><span style="color: $color;">$category</span><br><br>');

      buffer.writeln('<strong>Halstead Metrics:</strong><ul>');
      buffer
          .writeln('<li>Volume: ${halstead['volume'].toStringAsFixed(2)}</li>');
      buffer.writeln(
          '<li>Difficulty: ${halstead['difficulty'].toStringAsFixed(2)}</li>');
      buffer
          .writeln('<li>Effort: ${halstead['effort'].toStringAsFixed(2)}</li>');
      buffer.writeln(
          '<li>Time to Program: ${halstead['timeToProgram'].toStringAsFixed(2)} sec</li>');
      buffer.writeln(
          '<li>Delivered Bugs: ${halstead['deliveredBugs'].toStringAsFixed(2)}</li>');
      buffer.writeln('</ul>');

      if (recommendations.isNotEmpty) {
        buffer.writeln(
            '<strong>Recommendations:</strong><ul>$recommendations</ul>');
      }

      buffer.writeln('</div>'); // end of analysis panel

      buffer.writeln('</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table>');
  }

  static Map<String, dynamic> _calculateFileStats(
      List<FunctionComplexity> metrics) {
    if (metrics.isEmpty) return {'avgCMI': 0.0, 'totalLines': 0};

    final totalCMI =
        metrics.map((m) => m.maintainabilityIndex).reduce((a, b) => a + b);
    final totalLines = metrics.map((m) => m.lineCount).reduce((a, b) => a + b);

    return {
      'avgCMI': totalCMI / metrics.length,
      'totalLines': totalLines,
    };
  }

  static String getMIBadge(double mi) {
    if (mi >= MaintainabilityCalculator.excellentThreshold) {
      return '<span class="metric-badge excellent-mi">EXCELLENT</span>';
    } else if (mi >= MaintainabilityCalculator.goodThreshold) {
      return '<span class="metric-badge good-mi">GOOD</span>';
    } else if (mi >= MaintainabilityCalculator.moderateThreshold) {
      return '<span class="metric-badge moderate-mi">MODERATE</span>';
    } else if (mi >= MaintainabilityCalculator.poorThreshold) {
      return '<span class="metric-badge poor-mi">POOR</span>';
    } else {
      return '<span class="metric-badge legacy-mi">LEGACY</span>';
    }
  }

  static void _writeHtmlFooter(StringBuffer buffer) {
    buffer.writeln('''
    <script>
        function toggleCode(id) {
            const row = document.getElementById('code-' + id);
            if (row) {
                const isVisible = row.style.display === 'table-row';
                row.style.display = isVisible ? 'none' : 'table-row';
                
                // Update button text
                const toggleBtn = document.querySelector(`[onclick="toggleCode(\${id})"]`);
                if (toggleBtn) {
                    toggleBtn.textContent = isVisible ? 'View Code' : 'Hide Code';
                }
            }
        }
        
        // Add keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                // Hide all open code snippets
                document.querySelectorAll('.code-row').forEach(row => {
                    row.style.display = 'none';
                });
                document.querySelectorAll('.code-toggle').forEach(btn => {
                    btn.textContent = 'View Code';
                });
            }
        });
    </script>
</body>
</html>
    ''');
  }

  static Future<void> _writeReport(String content) async {
    await File(_outputFileName).writeAsString(content);
  }
}
