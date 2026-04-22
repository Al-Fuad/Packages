import 'dart:io';

/// Utility class for styled console output.
///
/// Provides methods for printing colored and formatted messages
/// to the terminal, including banners, success/error messages,
/// and interactive prompts.
class Console {
  // ANSI Colors
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';

  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  static const String bgBlue = '\x1B[44m';
  static const String bgGreen = '\x1B[42m';

  /// Prints the Archon CLI banner to the console.
  static void printBanner() {
    print('');
    print(
        '$cyan$bold╔══════════════════════════════════════════════════╗$reset');
    print(
        '$cyan$bold║            🔨  Archon CLI  v1.0.0                ║$reset');
    print(
        '$cyan$bold║     Clean Architecture Scaffold Generator        ║$reset');
    print(
        '$cyan$bold╚══════════════════════════════════════════════════╝$reset');
    print('');
  }

  /// Prints a success message in green.
  static void success(String msg) =>
      print('$green$bold✔  $reset$green$msg$reset');

  /// Prints an error message in red.
  static void error(String msg) => print('$red$bold✘  $reset$red$msg$reset');

  /// Prints an info message in cyan.
  static void info(String msg) => print('$cyan➤  $reset$msg');

  /// Prints a warning message in yellow.
  static void warning(String msg) =>
      print('$yellow$bold⚠  $reset$yellow$msg$reset');

  /// Prints a step/progress message in blue.
  static void step(String msg) => print('$blue$bold▶  $reset$bold$msg$reset');

  /// Prints a dimmed/faint message.
  static void dim_(String msg) => print('$dim$msg$reset');

  /// Prints a visual separator line.
  static void separator() =>
      print('$dim──────────────────────────────────────$reset');

  /// Prompts the user for input.
  ///
  /// Returns the user's input, or [defaultVal] if no input is provided.
  /// The [message] is displayed as the prompt text.
  static String? prompt(String message, {String? defaultVal}) {
    if (defaultVal != null) {
      stdout.write('$bold$message$reset $dim(default: $defaultVal)$reset: ');
    } else {
      stdout.write('$bold$message$reset: ');
    }
    final input = stdin.readLineSync()?.trim();
    if ((input == null || input.isEmpty) && defaultVal != null) {
      return defaultVal;
    }
    return input;
  }

  /// Displays a list of options and prompts the user to select one.
  ///
  /// Returns the index of the selected option.
  /// The [title] is displayed as the list heading.
  static int selectFromList(String title, List<String> options,
      {bool multiSelect = false}) {
    print('');
    print('$bold$blue$title$reset');
    for (int i = 0; i < options.length; i++) {
      print('  $cyan${i + 1}$reset. ${options[i]}');
    }
    print('');

    while (true) {
      final input = prompt('Enter number (1-${options.length})');
      final num = int.tryParse(input ?? '');
      if (num != null && num >= 1 && num <= options.length) {
        return num - 1;
      }
      error(
          'Invalid selection. Please enter a number between 1 and ${options.length}');
    }
  }

  /// Displays a list of options and prompts the user to select multiple.
  ///
  /// Returns a list of selected indices.
  /// The [title] is displayed as the list heading.
  static List<int> selectMultipleFromList(String title, List<String> options) {
    print('');
    print('$bold$blue$title$reset');
    print(
        '$dim(Enter comma-separated numbers, e.g: 1,2,3 — or press Enter for all)$reset');
    for (int i = 0; i < options.length; i++) {
      print('  $cyan${i + 1}$reset. ${options[i]}');
    }
    print('');

    while (true) {
      final input = prompt('Selection');
      if (input == null || input.isEmpty) {
        return List.generate(options.length, (i) => i);
      }
      final parts = input.split(',').map((e) => e.trim()).toList();
      final indices = <int>[];
      bool valid = true;
      for (final p in parts) {
        final num = int.tryParse(p);
        if (num == null || num < 1 || num > options.length) {
          valid = false;
          break;
        }
        indices.add(num - 1);
      }
      if (valid && indices.isNotEmpty) return indices;
      error('Invalid input. Please enter valid numbers separated by commas.');
    }
  }

  /// Prints a formatted list of features.
  static void printFeatureList(List<String> features) {
    print('');
    print('$bold${blue}📦 Features$reset');
    Console.separator();
    if (features.isEmpty) {
      print('  $dim(No features yet)$reset');
    } else {
      for (int i = 0; i < features.length; i++) {
        print('  $cyan${i + 1}$reset. ${features[i]}');
      }
    }
    Console.separator();
  }

  /// Prints a formatted list of usecases for a feature.
  static void printUsecaseList(String feature, List<String> usecases) {
    print('');
    print('$bold${blue}🧩 Usecases — $feature$reset');
    Console.separator();
    if (usecases.isEmpty) {
      print('  $dim(No usecases yet)$reset');
    } else {
      for (int i = 0; i < usecases.length; i++) {
        print('  $cyan${i + 1}$reset. ${usecases[i]}');
      }
    }
    Console.separator();
  }
}
