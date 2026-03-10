// Entry point that delegates to the individual test suites.
// Run with: dart test

import 'halstead_metrics_test.dart' as halstead;
import 'maintainability_calculator_test.dart' as maintainability;
import 'complexity_metrics_visitor_test.dart' as visitor;
import 'file_utils_test.dart' as file_utils;
import 'function_complexity_test.dart' as function_complexity;
import 'html_report_generator_test.dart' as html_report_generator;

void main() {
  halstead.main();
  maintainability.main();
  visitor.main();
  file_utils.main();
  function_complexity.main();
  html_report_generator.main();
}
