import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/console.dart';
import '../utils/fs_utils.dart';
import '../models/project_config.dart';
import 'create_project_command.dart';
import 'feature_manager_command.dart';

/// The main CLI entry point for Archon.
///
/// This class handles the command-line interface flow, including
/// detecting Flutter projects and routing to the appropriate commands.
class Cli {
  /// Runs the CLI with the given arguments.
  ///
  /// Detects if the current directory is a Flutter project and routes
  /// to the feature manager, or starts the project creation flow.
  Future<void> run(List<String> args) async {
    final currentDir = Directory.current.path;

    // If already in a Flutter project, skip creation and go to feature manager
    if (FsUtils.isFlutterProjectRoot(currentDir)) {
      Console.printBanner();
      Console.success('Flutter project detected at: ${p.basename(currentDir)}');
      Console.separator();

      final sm = _detectStateManagement(currentDir);
      Console.info('State management: ${sm.label}');

      await FeatureManagerCommand(
        projectPath: currentDir,
        stateManagement: sm,
      ).run();
      return;
    }

    // New project flow
    final createCommand = CreateProjectCommand();
    final config = await createCommand.run(currentDir);

    if (config == null) {
      Console.error('Project creation cancelled.');
      exit(1);
    }

    final projectDir = FsUtils.isFlutterProjectRoot(currentDir)
        ? currentDir
        : p.join(currentDir, config.name);

    // After creation, launch feature manager
    await FeatureManagerCommand(
      projectPath: projectDir,
      stateManagement: config.stateManagement,
    ).run();
  }

  StateManagement _detectStateManagement(String projectDir) {
    final pubspecPath = p.join(projectDir, 'pubspec.yaml');
    final content = FsUtils.readFile(pubspecPath);

    if (content.contains('flutter_bloc') || content.contains('bloc:')) {
      return StateManagement.bloc;
    } else if (content.contains('flutter_riverpod') ||
        content.contains('riverpod')) {
      return StateManagement.riverpod;
    } else if (content.contains("get:") || content.contains('get/get.dart')) {
      return StateManagement.getx;
    } else if (content.contains('provider:')) {
      return StateManagement.provider;
    }

    // Ask user if can't detect
    Console.warning('Could not auto-detect state management.');
    final idx = Console.selectFromList(
      'Select state management:',
      ['Provider', 'Riverpod', 'GetX', 'BLoC'],
    );
    return [
      StateManagement.provider,
      StateManagement.riverpod,
      StateManagement.getx,
      StateManagement.bloc,
    ][idx];
  }
}
