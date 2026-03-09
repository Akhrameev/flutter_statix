import 'dart:io';

Future<void> createTarball(String folderPath, String tarPath) async {
  final sourceDir = Directory(folderPath);

  // Check if source folder exists
  if (!await sourceDir.exists()) {
    print('❌ | Error: Folder does not exist: $folderPath');
    return;
  }

  print('📦 | Creating TAR archive from: $folderPath');
  print('💾 | Output: $tarPath');

  // Ensure output directory exists
  await File(tarPath).parent.create(recursive: true);

  // Build the tar command
  final result = await Process.run(
    'tar',
    ['-cvf', tarPath, '-C', folderPath, '.'],
  );

  if (result.exitCode == 0) {
    final fileSize = await File(tarPath).length();
    final sizeKB = (fileSize / 1024).toStringAsFixed(2);
    print('✅  | Success! Created $tarPath ($sizeKB KB)');
  } else {
    print('❌  | tar command failed:\n${result.stderr}');
  }
}

Future<void> main() async {
  final folderPath = 'flutter_statix';
  final tarPath = 'flutter_statix/flutter_statix_report.tar';

  try {
    await createTarball(folderPath, tarPath);
  } catch (e) {
    print('❌  | Error: $e');
    exit(1);
  }
}
