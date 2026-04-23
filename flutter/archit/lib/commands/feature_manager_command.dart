import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archit/models/project_config.dart';
import 'package:archit/utils/console.dart';
import 'package:archit/utils/fs_utils.dart';
import 'package:archit/generators/feature_generator.dart';
import 'package:archit/generators/usecase_generator.dart';

// ─────────────────────────────────────────────────────────────
//  ANSI helpers
// ─────────────────────────────────────────────────────────────
const _r  = '\x1B[0m';
const _b  = '\x1B[1m';
const _gr = '\x1B[32m';
const _cy = '\x1B[36m';
const _gy = '\x1B[90m';

// ─────────────────────────────────────────────────────────────
//  Arrow-key selector
//  Counts exact lines printed so redraw is pixel-perfect
// ─────────────────────────────────────────────────────────────
int _select(String prompt, List<String> options) {
  assert(options.isNotEmpty);

  int current = 0;

  // Total lines printed = 1 (prompt) + options.length
  final totalLines = 1 + options.length;

  void printMenu() {
    stdout.write('  $_cy$_b$prompt$_r\n');
    for (int i = 0; i < options.length; i++) {
      if (i == current) {
        stdout.write('  $_gr❯$_r $_b${options[i]}$_r\n');
      } else {
        stdout.write('  $_gy  ${options[i]}$_r\n');
      }
    }
  }

  void redraw() {
    // Move cursor up by totalLines, then clear to end of screen
    stdout.write('\x1B[${totalLines}A\x1B[0J');
    printMenu();
  }

  // Initial render — no blank line before, just the menu
  printMenu();

  stdin.echoMode = false;
  stdin.lineMode = false;

  try {
    while (true) {
      final b0 = stdin.readByteSync();

      if (b0 == 13 || b0 == 10) {
        // Enter — print one newline to separate from next output
        stdout.write('\n');
        break;
      } else if (b0 == 3) {
        stdout.write('\n');
        stdin.echoMode = true;
        stdin.lineMode = true;
        exit(0);
      } else if (b0 == 0x1B) {
        final b1 = stdin.readByteSync();
        final b2 = stdin.readByteSync();
        if (b1 == 0x5B) {
          if (b2 == 0x41 && current > 0) {
            current--;
            redraw();
          } else if (b2 == 0x42 && current < options.length - 1) {
            current++;
            redraw();
          }
        }
      }
    }
  } finally {
    stdin.echoMode = true;
    stdin.lineMode = true;
  }

  return current;
}

String _input(String prompt) {
  stdout.write('  $_cy\$$_r $_b$prompt$_r $_cy›$_r ');
  stdin.echoMode = true;
  stdin.lineMode = true;
  final val = stdin.readLineSync()?.trim() ?? '';
  return val;
}

// ─────────────────────────────────────────────────────────────
//  FeatureManagerCommand
// ─────────────────────────────────────────────────────────────
class FeatureManagerCommand {
  final String projectPath;
  final StateManagement stateManagement;

  FeatureManagerCommand({
    required this.projectPath,
    required this.stateManagement,
  });

  String get featuresPath => p.join(projectPath, 'lib', 'features');

  List<String> _getFeatures() {
    final dir = Directory(featuresPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .where((name) => name != '.gitkeep')
        .toList()
      ..sort();
  }

  List<String> _getUsecases(String featureName) {
    final dir = Directory(
        p.join(featuresPath, featureName, 'domain', 'usecases'));
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((n) => n.endsWith('_usecase'))
        .map((n) => n.replaceAll('_usecase', ''))
        .toList()
      ..sort();
  }

  Future<void> run() async {
    while (true) {
      final features = _getFeatures();
      Console.printFeatureList(features);   // panel — printed once, stays

      final options = [
        ...features.map((f) => '📁  $f'),
        '➕  Add new feature',
        '🚪  Exit',
      ];

      final idx = _select('Feature Manager', options);  // menu follows immediately

      if (idx == options.length - 1) {
        Console.info('Goodbye! Happy coding 🚀');
        break;
      } else if (idx == options.length - 2) {
        await _addFeature();
      } else {
        await _manageFeature(features[idx]);
      }
    }
  }

  Future<void> _addFeature() async {
    final name = _input('Feature name  (e.g. user_profile, auth)');
    if (name.isEmpty) {
      Console.error('Feature name cannot be empty.');
      return;
    }
    final snake = FsUtils.toSnakeCaseSafe(name);
    if (Directory(p.join(featuresPath, snake)).existsSync()) {
      Console.warning('Feature "$snake" already exists!');
      return;
    }
    Console.step('Generating feature: $snake...');
    FeatureGenerator(projectPath, stateManagement).generateFeature(snake);
    Console.success('Feature "$snake" created and registered in routes & DI!');
  }

  Future<void> _manageFeature(String featureName) async {
    while (true) {
      final usecases = _getUsecases(featureName);
      Console.printUsecaseList(featureName, usecases);  // panel — printed once

      final options = [
        ...usecases.map((u) => '🧩  $u'),
        '➕  Add new usecase',
        '⬅️   Back',
      ];

      final idx = _select('Feature: $featureName', options);  // menu follows immediately

      if (idx == options.length - 1) {
        break;
      } else if (idx == options.length - 2) {
        await _addUsecase(featureName);
      } else {
        Console.info('Usecase "${usecases[idx]}" is already generated.');
      }
    }
  }

  Future<void> _addUsecase(String featureName) async {
    final name = _input('Usecase name  (e.g. get_user, login, fetch_products)');
    if (name.isEmpty) {
      Console.error('Usecase name cannot be empty.');
      return;
    }
    final snake = FsUtils.toSnakeCaseSafe(name);
    Console.step('Generating usecase: $snake...');
    UsecaseGenerator(projectPath, stateManagement)
        .generateUsecase(featureName, snake);
    Console.success('UseCase "$snake" wired to datasource, repository & DI!');
  }
}