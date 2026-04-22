import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/project_config.dart';
import '../utils/console.dart';
import '../utils/fs_utils.dart';
import '../generators/feature_generator.dart';
import '../generators/usecase_generator.dart';

/// Command for managing features in a Flutter project.
///
/// Provides an interactive interface to add features and manage
/// their usecases within a clean architecture structure.
class FeatureManagerCommand {
  /// The path to the Flutter project.
  final String projectPath;

  /// The state management solution used in the project.
  final StateManagement stateManagement;

  /// Creates a new FeatureManagerCommand.
  ///
  /// Requires the [projectPath] to the Flutter project and the
  /// [stateManagement] strategy being used.
  FeatureManagerCommand({
    required this.projectPath,
    required this.stateManagement,
  });

  /// Returns the path to the features directory.
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
    final usecasesDir =
        Directory(p.join(featuresPath, featureName, 'domain', 'usecases'));
    if (!usecasesDir.existsSync()) return [];
    return usecasesDir
        .listSync()
        .whereType<File>()
        .map((f) => p.basenameWithoutExtension(f.path))
        .where((name) => name.endsWith('_usecase'))
        .map((name) => name.replaceAll('_usecase', ''))
        .toList()
      ..sort();
  }

  /// Runs the feature manager interactive loop.
  ///
  /// Displays the feature list and allows the user to add new features
  /// or manage existing ones.
  Future<void> run() async {
    while (true) {
      final features = _getFeatures();
      Console.printFeatureList(features);

      final options = <String>[
        ...features,
        '➕  Add new feature',
        '🚪  Exit',
      ];

      final idx = Console.selectFromList(
        '🗂️  Feature Manager — What do you want to do?',
        options,
      );

      if (idx == options.length - 1) {
        // Exit
        Console.info('Goodbye! Happy coding 🚀');
        break;
      } else if (idx == options.length - 2) {
        // Add new feature
        await _addFeature();
      } else {
        // Manage existing feature
        await _manageFeature(features[idx]);
      }
    }
  }

  Future<void> _addFeature() async {
    print('');
    final name = Console.prompt('Enter feature name (e.g. user_profile, auth)');
    if (name == null || name.isEmpty) {
      Console.error('Feature name cannot be empty.');
      return;
    }

    final featureSnake = FsUtils.toSnakeCaseSafe(name);
    final featureDir = Directory(p.join(featuresPath, featureSnake));

    if (featureDir.existsSync()) {
      Console.warning('Feature "$featureSnake" already exists!');
      return;
    }

    Console.step('Generating feature: $featureSnake...');
    final generator = FeatureGenerator(projectPath, stateManagement);
    generator.generateFeature(featureSnake);

    Console.success(
        'Feature "$featureSnake" created and registered in routes & DI!');
  }

  Future<void> _manageFeature(String featureName) async {
    while (true) {
      final usecases = _getUsecases(featureName);
      Console.printUsecaseList(featureName, usecases);

      final options = <String>[
        ...usecases,
        '➕  Add new usecase',
        '⬅️   Back to features',
      ];

      final idx = Console.selectFromList(
        '🧩 Feature: $featureName',
        options,
      );

      if (idx == options.length - 1) {
        // Back
        break;
      } else if (idx == options.length - 2) {
        // Add usecase
        await _addUsecase(featureName);
      } else {
        Console.info('Usecase "${usecases[idx]}" — already generated.');
      }
    }
  }

  Future<void> _addUsecase(String featureName) async {
    print('');
    final name = Console.prompt(
        'Enter usecase name (e.g. get_user, login, fetch_products)');
    if (name == null || name.isEmpty) {
      Console.error('Usecase name cannot be empty.');
      return;
    }

    final usecaseSnake = FsUtils.toSnakeCaseSafe(name);
    Console.step('Generating usecase: $usecaseSnake...');

    final generator = UsecaseGenerator(projectPath, stateManagement);
    generator.generateUsecase(featureName, usecaseSnake);

    Console.success(
        'UseCase "$usecaseSnake" created and wired to datasource, repository & DI!');
  }
}
