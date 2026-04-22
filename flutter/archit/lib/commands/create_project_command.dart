import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/project_config.dart';
import '../utils/console.dart';
import '../utils/fs_utils.dart';
import '../generators/pubspec_generator.dart';
import '../generators/core_generator.dart';
import '../generators/app_generator.dart';

/// Command for creating new Flutter projects.
///
/// Handles the interactive project creation process, including
/// project type, platform selection, and state management configuration.
class CreateProjectCommand {
  /// Runs the project creation command.
  ///
  /// Returns a [ProjectConfig] if creation succeeds, or null if cancelled.
  /// The [currentDir] parameter specifies the directory where the project
  /// will be created or detected.
  Future<ProjectConfig?> run(String currentDir) async {
    Console.printBanner();

    String projectDir = currentDir;
    String projectName;

    // Check if current directory is a Flutter project
    if (FsUtils.isFlutterProjectRoot(currentDir)) {
      final pubspec = File(p.join(currentDir, 'pubspec.yaml'));
      final content = pubspec.readAsStringSync();
      final nameMatch =
          RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
      projectName = nameMatch?.group(1) ?? p.basename(currentDir);
      Console.success('Flutter project detected: $projectName');
    } else {
      Console.info('No Flutter project found in current directory.');
      final name = Console.prompt('Enter project name (snake_case)');
      if (name == null || name.isEmpty) {
        Console.error('Project name cannot be empty.');
        return null;
      }
      projectName = FsUtils.toSnakeCaseSafe(name);
      projectDir = p.join(currentDir, projectName);
    }

    // Project type
    final typeIndex = Console.selectFromList(
      '📱 Select project type:',
      ['Application (app)', 'Package'],
    );
    final projectType = typeIndex == 0 ? ProjectType.app : ProjectType.package;

    // Platform selection
    final platformLabels = [
      'Android',
      'iOS',
      'Web',
      'Windows',
      'macOS',
      'Linux'
    ];
    final platformValues = [
      Platform.android,
      Platform.ios,
      Platform.web,
      Platform.windows,
      Platform.macos,
      Platform.linux,
    ];
    final platformIndices = Console.selectMultipleFromList(
      '🖥️  Select target platforms:',
      platformLabels,
    );
    final platforms = platformIndices.map((i) => platformValues[i]).toList();

    // State management
    final smIndex = Console.selectFromList(
      '⚡ Select state management:',
      ['Provider', 'Riverpod', 'GetX', 'BLoC'],
    );
    final smValues = [
      StateManagement.provider,
      StateManagement.riverpod,
      StateManagement.getx,
      StateManagement.bloc,
    ];
    final stateManagement = smValues[smIndex];

    final config = ProjectConfig(
      name: projectName,
      type: projectType,
      platforms: platforms,
      stateManagement: stateManagement,
    );

    Console.separator();
    Console.step('Creating Flutter project...');

    await _scaffoldProject(config, projectDir, currentDir);

    return config;
  }

  Future<void> _scaffoldProject(
      ProjectConfig config, String projectDir, String currentDir) async {
    final isExisting = FsUtils.isFlutterProjectRoot(currentDir);

    if (!isExisting) {
      // Run flutter create
      Console.info('Running: flutter create ${config.name}');
      final platformArgs = config.platforms.map((p) => p.label).join(',');
      final result = await Process.run(
        'flutter',
        [
          'create',
          '--org',
          'com.example',
          '--platforms',
          platformArgs,
          config.name,
        ],
        workingDirectory: currentDir,
      );

      if (result.exitCode != 0) {
        Console.error('flutter create failed:\n${result.stderr}');
        exit(1);
      }
      Console.success('Flutter project created!');
    }

    // Write pubspec.yaml
    Console.info('Writing pubspec.yaml with pre-configured packages...');
    FsUtils.writeFile(
      p.join(projectDir, 'pubspec.yaml'),
      generatePubspec(config),
    );

    // Create assets directories
    for (final dir in ['assets/images', 'assets/icons', 'assets/animations']) {
      FsUtils.createDir(p.join(projectDir, dir));
      FsUtils.writeFile(p.join(projectDir, dir, '.gitkeep'), '');
    }

    // Generate core layer
    Console.info('Generating core architecture...');
    final coreGen = CoreGenerator(projectDir, config);
    coreGen.generate();

    // Generate app.dart and main.dart
    Console.info('Generating app entry points...');
    final appGen = AppGenerator(projectDir, config);
    appGen.generate();

    // Create features directory placeholder
    FsUtils.writeFile(p.join(projectDir, 'lib', 'features', '.gitkeep'), '');

    // Run flutter pub get
    Console.info('Running flutter pub get...');
    final pubGet = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectDir,
    );
    if (pubGet.exitCode == 0) {
      Console.success('Dependencies installed!');
    } else {
      Console.warning('flutter pub get had issues (can run manually)');
    }

    Console.separator();
    Console.success('Project "${config.name}" created successfully!');
    Console.info('State Management: ${config.stateManagement.label}');
    Console.info(
        'Platforms: ${config.platforms.map((p) => p.label).join(', ')}');
    Console.separator();
  }
}
