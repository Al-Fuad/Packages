/// Available state management solutions.
enum StateManagement { provider, riverpod, getx, bloc }

/// Types of Flutter projects that can be created.
enum ProjectType { app, package }

/// Target platforms for Flutter projects.
enum Platform { android, ios, web, windows, macos, linux }

/// Extension providing additional properties for [StateManagement].
extension StateManagementExt on StateManagement {
  /// Returns the human-readable label for this state management solution.
  String get label {
    switch (this) {
      case StateManagement.provider:
        return 'Provider';
      case StateManagement.riverpod:
        return 'Riverpod';
      case StateManagement.getx:
        return 'GetX';
      case StateManagement.bloc:
        return 'BLoC';
    }
  }

  /// Returns the pubspec package dependency string for this state management solution.
  String get packageName {
    switch (this) {
      case StateManagement.provider:
        return 'provider: ^6.1.2';
      case StateManagement.riverpod:
        return 'flutter_riverpod: ^2.5.1';
      case StateManagement.getx:
        return 'get: ^4.6.6';
      case StateManagement.bloc:
        return 'flutter_bloc: ^8.1.5\n  bloc: ^8.1.4';
    }
  }

  /// Returns additional packages required for this state management solution.
  String get extraPackages {
    switch (this) {
      case StateManagement.getx:
        return '';
      default:
        return '  go_router: ^14.2.7';
    }
  }
}

/// Extension providing additional properties for [Platform].
extension PlatformExt on Platform {
  /// Returns the platform identifier string.
  String get label {
    switch (this) {
      case Platform.android:
        return 'android';
      case Platform.ios:
        return 'ios';
      case Platform.web:
        return 'web';
      case Platform.windows:
        return 'windows';
      case Platform.macos:
        return 'macos';
      case Platform.linux:
        return 'linux';
    }
  }
}

/// Configuration for a Flutter project.
///
/// Contains all the settings needed to scaffold a Flutter project
/// with clean architecture.
class ProjectConfig {
  /// The project name in snake_case.
  final String name;

  /// The type of project (app or package).
  final ProjectType type;

  /// The target platforms for this project.
  final List<Platform> platforms;

  /// The state management solution to use.
  final StateManagement stateManagement;

  /// Creates a new ProjectConfig.
  ///
  /// All parameters are required.
  ProjectConfig({
    required this.name,
    required this.type,
    required this.platforms,
    required this.stateManagement,
  });
}
