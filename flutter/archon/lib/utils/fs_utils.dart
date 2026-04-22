import 'dart:io';
import 'package:path/path.dart' as p;

/// Utility class for file system operations.
///
/// Provides helper methods for common file system tasks
/// including project detection, file I/O, and string case conversion.
class FsUtils {
  /// Checks if the given directory is a Flutter project root.
  ///
  /// Returns true if pubspec.yaml exists and contains Flutter configuration.
  static bool isFlutterProjectRoot(String dir) {
    final pubspec = File(p.join(dir, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return false;
    final content = pubspec.readAsStringSync();
    return content.contains('flutter:') || content.contains('sdk: flutter');
  }

  /// Creates a directory at [path], including parent directories.
  static void createDir(String path) {
    Directory(path).createSync(recursive: true);
  }

  /// Writes [content] to the file at [path], creating parent directories if needed.
  static void writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Appends [content] to the file at [path].
  ///
  /// Creates the file if it doesn't exist.
  static void appendToFile(String path, String content) {
    final file = File(path);
    if (file.existsSync()) {
      file.writeAsStringSync(file.readAsStringSync() + content);
    } else {
      writeFile(path, content);
    }
  }

  /// Reads and returns the content of the file at [path].
  ///
  /// Returns an empty string if the file doesn't exist.
  static String readFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return '';
    return file.readAsStringSync();
  }

  /// Returns true if a file exists at [path].
  static bool fileExists(String path) => File(path).existsSync();

  /// Returns true if a directory exists at [path].
  static bool dirExists(String path) => Directory(path).existsSync();

  /// Replaces all occurrences of [from] with [to] in the file at [path].
  static void replaceInFile(String path, String from, String to) {
    final file = File(path);
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    file.writeAsStringSync(content.replaceAll(from, to));
  }

  /// Converts snake_case to PascalCase.
  static String toPascalCase(String input) {
    return input
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join('');
  }

  /// Converts PascalCase or camelCase to snake_case.
  static String toSnakeCase(String input) {
    return input
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => '_${match.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Safely converts any input to snake_case.
  ///
  /// Handles spaces, hyphens, and mixed case by converting
  /// everything to lowercase and replacing spaces/hyphens with underscores.
  static String toSnakeCaseSafe(String input) {
    // handle input that may already be snake_case or mixed
    final lower =
        input.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return lower;
  }
}
