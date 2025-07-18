import 'analysis_config.dart';
import 'dart:convert';
import 'dart:io';

class HtmlReportGenerator {
  final AnalysisConfig config;

  HtmlReportGenerator(this.config);

  Future<void> generate() async {
    print('📁 | Generating Analysis Report...');
    final inputFile = File(config.dartAnalysisParsedJsonFile);
    final outputFile = File(config.dartAnalysisReportFile);

    if (!await inputFile.exists()) {
      print('❌ | Error: Parsed Json File Not Found at ${inputFile.path}');
      exit(1);
    }

    print('📊 | Generating HTML Report from Parsed JSON File ${inputFile.path}...');

    final content = await inputFile.readAsString();
    if (content.trim().isEmpty) {
      print('⚠️ | Warning: Parsed JSON File is Empty');
      await _generateEmptyReport(outputFile);
      return;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('❌ | Error: Invalid JSON Format in Parsed Report File: $e');
      exit(1);
    }

    final issues = (data['issues'] as List<dynamic>?) ?? [];
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

    print('📋 | Processing ${issues.length} Issues...');

    final stats = _calculateStatistics(issues);
    final html = _generateHtmlContent(issues, stats, metadata);

    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(html);

    print('✅  | HTML Report Generated at: ${outputFile.path}');
  }
}

Map<String, int> _calculateStatistics(List<dynamic> issues) {
  final stats = <String, int>{
    'MAJOR': 0,
    'MINOR': 0,
    'INFO': 0,
    'total': issues.length,
  };

  for (final issue in issues) {
    final severity = (issue['severity'] as String?)?.toUpperCase() ?? 'INFO';
    stats[severity] = (stats[severity] ?? 0) + 1;
  }

  return stats;
}

String _generateHtmlContent(
    List<dynamic> issues,
    Map<String, int> stats,
    Map<String, dynamic> metadata,
    ) {
  final buffer = StringBuffer();

  // HTML head
  buffer.writeln(_generateHtmlHead());

  // Body start
  buffer.writeln('<body>');
  buffer.writeln('<div class="container">');

  // Header
  buffer.writeln(_generateHeader(stats, metadata));

  // Summary cards
  buffer.writeln(_generateSummaryCards(stats));

  // Issues table
  if (issues.isNotEmpty) {
    buffer.writeln(_generateIssuesTable(issues));
  } else {
    buffer.writeln('<div class="no-issues">');
    buffer.writeln('<h2>🎉 No Issues Found!</h2>');
    buffer.writeln('<p>Your code analysis completed successfully with no issues detected.</p>');
    buffer.writeln('</div>');
  }

  // Footer
  buffer.writeln(_generateFooter());

  buffer.writeln('</div>'); // container
  buffer.writeln('</body></html>');

  return buffer.toString();
}

String _generateHtmlHead() {
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dart Static Analysis Report</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      padding: 20px;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background: white;
      border-radius: 12px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.1);
      overflow: hidden;
    }
    
    .header {
      background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
      color: white;
      padding: 40px 30px;
      text-align: center;
    }
    
    .header h1 {
      font-size: 2.5em;
      margin-bottom: 10px;
      font-weight: 300;
    }
    
    .header .subtitle {
      opacity: 0.9;
      font-size: 1.1em;
    }
    
    .summary-cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      padding: 30px;
      background: #f8f9fa;
    }
    
    .card {
      background: white;
      padding: 25px;
      border-radius: 10px;
      text-align: center;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      transition: transform 0.2s ease;
    }
    
    .card:hover {
      transform: translateY(-2px);
    }
    
    .card .number {
      font-size: 2.5em;
      font-weight: bold;
      margin-bottom: 10px;
    }
    
    .card .label {
      color: #666;
      font-size: 0.9em;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    
    .card.total .number { color: #3498db; }
    .card.major .number { color: #f34a12; }
    .card.minor .number { color: #f1c40f; }
    .card.info .number { color: #3498db; }
    
    .table-container {
      padding: 30px;
      overflow-x: auto;
    }
    
    .filter-controls {
      margin-bottom: 20px;
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }
    
    .filter-btn {
      padding: 8px 16px;
      border: 1px solid #ddd;
      background: white;
      border-radius: 20px;
      cursor: pointer;
      transition: all 0.2s ease;
      font-size: 0.9em;
    }
    
    .filter-btn:hover { background: #f8f9fa; }
    .filter-btn.active { background: #3498db; color: white; border-color: #3498db; }
    
    table {
      width: 100%;
      border-collapse: collapse;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    
    th {
      background: #34495e;
      color: white;
      padding: 15px 12px;
      text-align: left;
      font-weight: 600;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    
    td {
      padding: 12px;
      border-bottom: 1px solid #ecf0f1;
      vertical-align: top;
    }
    
    tr:hover {
      background: #f8f9fa;
    }
    
    .severity-badge {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 0.8em;
      font-weight: bold;
      text-transform: uppercase;
      display: inline-block;
    }
    
    .severity-MAJOR { background: #f34a12; color: white; }
    .severity-MINOR { background: #f1c40f; color: #333; }
    .severity-INFO { background: #3498db; color: white; }
    
    .file-path {
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      font-size: 0.9em;
      color: #2c3e50;
      word-break: break-all;
    }
    
    .line-col {
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      font-size: 0.9em;
      color: #7f8c8d;
    }
    
    .message {
      max-width: 400px;
      word-wrap: break-word;
    }
    
    .rule-id {
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      font-size: 0.8em;
      background: #ecf0f1;
      padding: 2px 6px;
      border-radius: 4px;
      color: #2c3e50;
    }
    
    .no-issues {
      text-align: center;
      padding: 60px 30px;
      color: #27ae60;
    }
    
    .no-issues h2 {
      font-size: 2em;
      margin-bottom: 15px;
    }
    
    .footer {
      background: #ecf0f1;
      padding: 20px 30px;
      text-align: center;
      color: #7f8c8d;
      font-size: 0.9em;
    }
    
    .search-box {
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 20px;
      width: 250px;
      font-size: 0.9em;
    }
    
    @media (max-width: 768px) {
      .container { margin: 10px; }
      .header { padding: 20px; }
      .header h1 { font-size: 1.8em; }
      .summary-cards { padding: 20px; gap: 15px; }
      .table-container { padding: 20px; }
      .filter-controls { flex-direction: column; align-items: stretch; }
      .search-box { width: 100%; }
    }
  </style>
</head>''';
}

String _generateHeader(Map<String, int> stats, Map<String, dynamic> metadata) {
  final timestamp = metadata['timestamp'] ?? DateTime.now().toIso8601String();

  return '''
<div class="header">
  <h1>🔍 Dart Static Analysis Report</h1>
  <div class="subtitle">
    Generated on ${_formatTimestamp(timestamp)}
  </div>
</div>''';
}

String _generateSummaryCards(Map<String, int> stats) {
  return '''
<div class="summary-cards">
  <div class="card total">
    <div class="number">${stats['total']}</div>
    <div class="label">Total Issues</div>
  </div>
  <div class="card major">
    <div class="number">${stats['MAJOR'] ?? 0}</div>
    <div class="label">Major (Error)</div>
  </div>
  <div class="card minor">
    <div class="number">${stats['MINOR'] ?? 0}</div>
    <div class="label">Minor (Warning)</div>
  </div>
  <div class="card info">
    <div class="number">${stats['INFO'] ?? 0}</div>
    <div class="label">Info (Informational)</div>
  </div>
</div>''';
}

String _generateIssuesTable(List<dynamic> issues) {
  final buffer = StringBuffer();

  buffer.writeln('<div class="table-container">');
  buffer.writeln('<div class="filter-controls">');
  buffer.writeln('<input type="text" class="search-box" placeholder="🔍 Search issues..." id="searchBox">');
  buffer.writeln('<button class="filter-btn active" data-filter="all">All</button>');
  buffer.writeln('<button class="filter-btn" data-filter="MAJOR">Major</button>');
  buffer.writeln('<button class="filter-btn" data-filter="MINOR">Minor</button>');
  buffer.writeln('<button class="filter-btn" data-filter="INFO">Info</button>');
  buffer.writeln('</div>');

  buffer.writeln('<table id="issuesTable">');
  buffer.writeln('<thead>');
  buffer.writeln('<tr>');
  buffer.writeln('<th>Severity</th>');
  buffer.writeln('<th>File</th>');
  buffer.writeln('<th>Location</th>');
  buffer.writeln('<th>Message</th>');
  buffer.writeln('<th>Rule</th>');
  buffer.writeln('</tr>');
  buffer.writeln('</thead>');
  buffer.writeln('<tbody>');

  for (final issue in issues) {
    final severity = (issue['severity'] as String?)?.toUpperCase() ?? 'INFO';
    final location = issue['primaryLocation'] as Map<String, dynamic>? ?? {};
    final file = location['filePath'] as String? ?? 'unknown';
    final message = location['message'] as String? ?? '';
    final textRange = location['textRange'] as Map<String, dynamic>? ?? {};
    final line = textRange['startLine'] ?? 0;
    final column = textRange['startColumn'] ?? 0;
    final ruleId = issue['ruleId'] as String? ?? 'unknown';

    // Extract just the filename for display
    final fileName = file.split('/').last;
    final relativePath = file.startsWith('/') ? file.substring(1) : file;

    buffer.writeln('<tr data-severity="$severity">');
    buffer.writeln('<td><span class="severity-badge severity-$severity">$severity</span></td>');
    buffer.writeln('<td><span class="file-path" title="$relativePath">$fileName</span></td>');
    buffer.writeln('<td><span class="line-col">$line:$column</span></td>');
    buffer.writeln('<td><div class="message">${htmlEscape.convert(message)}</div></td>');
    buffer.writeln('<td><span class="rule-id">$ruleId</span></td>');
    buffer.writeln('</tr>');
  }

  buffer.writeln('</tbody>');
  buffer.writeln('</table>');
  buffer.writeln('</div>');

  // Add JavaScript for filtering and searching
  buffer.writeln(_generateJavaScript());

  return buffer.toString();
}

String _generateJavaScript() {
  return '''
<script>
document.addEventListener('DOMContentLoaded', function() {
  const searchBox = document.getElementById('searchBox');
  const filterBtns = document.querySelectorAll('.filter-btn');
  const table = document.getElementById('issuesTable');
  const rows = table.querySelectorAll('tbody tr');
  
  let currentFilter = 'all';
  
  // Filter functionality
  filterBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      filterBtns.forEach(b => b.classList.remove('active'));
      this.classList.add('active');
      currentFilter = this.dataset.filter;
      filterRows();
    });
  });
  
  // Search functionality
  searchBox.addEventListener('input', filterRows);
  
  function filterRows() {
    const searchTerm = searchBox.value.toLowerCase();
    
    rows.forEach(row => {
      const severity = row.dataset.severity;
      const text = row.textContent.toLowerCase();
      
      const matchesFilter = currentFilter === 'all' || severity === currentFilter;
      const matchesSearch = searchTerm === '' || text.includes(searchTerm);
      
      row.style.display = matchesFilter && matchesSearch ? '' : 'none';
    });
    
    updateVisibleCount();
  }
  
  function updateVisibleCount() {
    const visibleRows = Array.from(rows).filter(row => row.style.display !== 'none');
    const totalRows = rows.length;
    
    // Update the search box placeholder
    searchBox.placeholder = \`🔍 Search issues... (\${visibleRows.length}/\${totalRows} shown)\`;
  }
  
  // Initialize
  updateVisibleCount();
});
</script>''';
}

String _generateFooter() {
  return '''
<div class="footer">
  <p>Generated by Flutter Statix • <a href="https://pub.dev/packages/flutter_statix" target="_blank">Learn about Flutter Statix</a></p>
</div>''';
}

String _formatTimestamp(String timestamp) {
  try {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return timestamp;
  }
}

Future<void> _generateEmptyReport(File outputFile) async {
  final html = _generateHtmlContent([], {'total': 0}, {});
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(html);
  print('✅ Empty HTML Report Generated at: ${outputFile.path}');
}