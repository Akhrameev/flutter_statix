import 'dart:io';

import 'package:test/test.dart';

import '../bin/dart_metrics/file_utils.dart';

void main() {
  group('FileUtils.isEmptyOrMinimalFile', () {
    test('empty string is considered minimal', () {
      expect(FileUtils.isEmptyOrMinimalFile(''), isTrue);
    });

    test('whitespace-only content is considered minimal', () {
      expect(FileUtils.isEmptyOrMinimalFile('   \n\n  '), isTrue);
    });

    test('single-line comment only is considered minimal', () {
      expect(FileUtils.isEmptyOrMinimalFile('// just a comment'), isTrue);
    });

    test('multi-line comments only are considered minimal', () {
      const content = '''
// First comment
// Second comment
// Third comment
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });

    test('block comment only is considered minimal', () {
      const content = '''
/* This is a block
   comment across lines */
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });

    test('imports and exports only are considered minimal', () {
      const content = '''
import 'dart:io';
export 'src/something.dart';
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });

    test('part directives only are considered minimal', () {
      const content = "part 'src/something.dart';";
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });

    test('imports plus 2 meaningful lines is still minimal', () {
      // 'class Foo {}' counts as 1 meaningful line (just the class declaration
      // but the body '{}'may count depending on trimming); ensure < 3
      // Use exactly 2 unambiguous meaningful lines:
      const content = "import 'dart:io';\nint x = 1;\nint y = 2;";
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });

    test('3 or more meaningful lines is NOT minimal', () {
      const content = '''
import 'dart:io';

int a = 1;
int b = 2;
int c = 3;
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isFalse);
    });

    test('class with fields is NOT minimal', () {
      const content = '''
class Config {
  final String host;
  final int port;
  final bool secure;
}
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isFalse);
    });

    test('function declaration is NOT minimal', () {
      const content = '''
int add(int a, int b) {
  return a + b;
}

int sub(int a, int b) {
  return a - b;
}
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isFalse);
    });

    test('asterisk doc-comment lines are treated as comments', () {
      const content = '''
/**
 * This is a doc comment.
 * Multiple lines.
 */
''';
      expect(FileUtils.isEmptyOrMinimalFile(content), isTrue);
    });
  });

  group('FileUtils.getDartFiles', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_utils_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns only .dart files from the directory', () {
      File('${tempDir.path}/a.dart').writeAsStringSync('void main() {}');
      File('${tempDir.path}/b.dart').writeAsStringSync('int x = 1;');
      File('${tempDir.path}/c.txt').writeAsStringSync('not dart');
      File('${tempDir.path}/d.yaml').writeAsStringSync('key: value');

      final files = FileUtils.getDartFiles(tempDir);
      expect(files, hasLength(2));
      expect(files.map((f) => f.path), everyElement(endsWith('.dart')));
    });

    test('finds .dart files recursively in subdirectories', () {
      final sub = Directory('${tempDir.path}/sub')..createSync();
      File('${tempDir.path}/root.dart').writeAsStringSync('');
      File('${sub.path}/nested.dart').writeAsStringSync('');

      final files = FileUtils.getDartFiles(tempDir);
      expect(files, hasLength(2));
    });

    test('returns empty list when no .dart files exist', () {
      File('${tempDir.path}/readme.txt').writeAsStringSync('hello');
      expect(FileUtils.getDartFiles(tempDir), isEmpty);
    });
  });

  group('FileUtils.readFileContent', () {
    test('reads file content successfully', () async {
      final file = File(
          '${Directory.systemTemp.path}/read_content_test_${DateTime.now().microsecondsSinceEpoch}.dart')
        ..writeAsStringSync('void main() {}');
      final content = await FileUtils.readFileContent(file);
      expect(content, equals('void main() {}'));
      file.deleteSync();
    });

    test('returns null for a non-existent file', () async {
      final fake = File('/nonexistent/path/that/does/not/exist.dart');
      final content = await FileUtils.readFileContent(fake);
      expect(content, isNull);
    });
  });
}
