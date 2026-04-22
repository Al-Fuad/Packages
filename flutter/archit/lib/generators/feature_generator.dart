import 'package:path/path.dart' as p;
import 'package:archit/utils/fs_utils.dart';
import 'package:archit/models/project_config.dart';

/// Generates a new feature with clean architecture layers.
///
/// Creates the data, domain, and presentation layers for a feature,
/// along with route registration and dependency injection setup.
class FeatureGenerator {
  /// The path to the Flutter project.
  final String projectPath;

  /// The state management solution used in the project.
  final StateManagement stateManagement;

  /// Creates a new FeatureGenerator.
  ///
  /// Requires the [projectPath] and [stateManagement] strategy.
  FeatureGenerator(this.projectPath, this.stateManagement);

  /// Returns the path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Generates a complete feature structure.
  ///
  /// Creates the data, domain, and presentation layers,
  /// registers routes, and updates dependency injection.
  /// The [featureName] should be in snake_case.
  void generateFeature(String featureName) {
    final snake = FsUtils.toSnakeCaseSafe(featureName);
    final pascal = FsUtils.toPascalCase(snake);
    final featurePath = p.join(libPath, 'features', snake);

    _generateDataLayer(featurePath, snake, pascal);
    _generateDomainLayer(featurePath, snake, pascal);
    _generatePresentationLayer(featurePath, snake, pascal);
    _registerRoute(snake, pascal);
    _updateDI(snake, pascal);
  }

  void _generateDataLayer(String featurePath, String snake, String pascal) {
    // Remote data source
    FsUtils.writeFile(
        p.join(featurePath, 'data', 'datasources',
            '${snake}_remote_datasource.dart'),
        '''
import '../../../../core/network/api_client.dart';
import '../models/${snake}_model.dart';

abstract class ${pascal}RemoteDataSource {
  // Add your remote data source methods here
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  final ApiClient apiClient;

  ${pascal}RemoteDataSourceImpl({required this.apiClient});

  // Implement methods here
}
''');

    // Model
    FsUtils.writeFile(
        p.join(featurePath, 'data', 'models', '${snake}_model.dart'), '''
import 'package:equatable/equatable.dart';
import '../../domain/entities/${snake}_entity.dart';

class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model({
    required super.id,
  });

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }

  factory ${pascal}Model.fromEntity(${pascal}Entity entity) {
    return ${pascal}Model(id: entity.id);
  }
}
''');

    // Repository impl
    FsUtils.writeFile(
        p.join(featurePath, 'data', 'repositories',
            '${snake}_repository_impl.dart'),
        '''
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/${snake}_repository.dart';
import '../datasources/${snake}_remote_datasource.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}RemoteDataSource remoteDataSource;

  ${pascal}RepositoryImpl({required this.remoteDataSource});

  // Implement repository methods here
}
''');
  }

  void _generateDomainLayer(String featurePath, String snake, String pascal) {
    // Entity
    FsUtils.writeFile(
        p.join(featurePath, 'domain', 'entities', '${snake}_entity.dart'), '''
import 'package:equatable/equatable.dart';

class ${pascal}Entity extends Equatable {
  final String id;

  const ${pascal}Entity({required this.id});

  @override
  List<Object?> get props => [id];
}
''');

    // Repository interface
    FsUtils.writeFile(
        p.join(
            featurePath, 'domain', 'repositories', '${snake}_repository.dart'),
        '''
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class ${pascal}Repository {
  // Define repository contracts here
}
''');
  }

  void _generatePresentationLayer(
      String featurePath, String snake, String pascal) {
    switch (stateManagement) {
      case StateManagement.provider:
        _generateProviderPresentation(featurePath, snake, pascal);
        break;
      case StateManagement.riverpod:
        _generateRiverpodPresentation(featurePath, snake, pascal);
        break;
      case StateManagement.getx:
        _generateGetxPresentation(featurePath, snake, pascal);
        break;
      case StateManagement.bloc:
        _generateBlocPresentation(featurePath, snake, pascal);
        break;
    }
  }

  void _generateProviderPresentation(
      String featurePath, String snake, String pascal) {
    FsUtils.writeFile(
        p.join(
            featurePath, 'presentation', 'providers', '${snake}_provider.dart'),
        '''
import 'package:flutter/foundation.dart';

enum ${pascal}Status { initial, loading, success, failure }

class ${pascal}Provider extends ChangeNotifier {
  ${pascal}Status _status = ${pascal}Status.initial;
  String? _errorMessage;

  ${pascal}Status get status => _status;
  String? get errorMessage => _errorMessage;

  void _setLoading() {
    _status = ${pascal}Status.loading;
    notifyListeners();
  }

  void _setSuccess() {
    _status = ${pascal}Status.success;
    notifyListeners();
  }

  void _setError(String message) {
    _status = ${pascal}Status.failure;
    _errorMessage = message;
    notifyListeners();
  }
}
''');

    _generateScreen(featurePath, snake, pascal, 'Provider');
  }

  void _generateRiverpodPresentation(
      String featurePath, String snake, String pascal) {
    FsUtils.writeFile(
        p.join(
            featurePath, 'presentation', 'providers', '${snake}_provider.dart'),
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ${pascal}Status { initial, loading, success, failure }

class ${pascal}State {
  final ${pascal}Status status;
  final String? errorMessage;

  const ${pascal}State({
    this.status = ${pascal}Status.initial,
    this.errorMessage,
  });

  ${pascal}State copyWith({
    ${pascal}Status? status,
    String? errorMessage,
  }) {
    return ${pascal}State(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ${pascal}Notifier extends StateNotifier<${pascal}State> {
  ${pascal}Notifier() : super(const ${pascal}State());
}

final ${snake}Provider = StateNotifierProvider<${pascal}Notifier, ${pascal}State>(
  (ref) => ${pascal}Notifier(),
);
''');

    _generateScreen(featurePath, snake, pascal, 'ConsumerWidget');
  }

  void _generateGetxPresentation(
      String featurePath, String snake, String pascal) {
    // Controller
    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'controllers',
            '${snake}_controller.dart'),
        '''
import 'package:get/get.dart';

class ${pascal}Controller extends GetxController {
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
  }
}
''');

    // Binding
    FsUtils.writeFile(
        p.join(featurePath, 'bindings', '${snake}_binding.dart'), '''
import 'package:get/get.dart';
import '../presentation/controllers/${snake}_controller.dart';
import '../../core/di/injection_container.dart';

class ${pascal}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<${pascal}Controller>(() => ${pascal}Controller());
  }
}
''');

    _generateScreen(featurePath, snake, pascal, 'GetView<${pascal}Controller>');
  }

  void _generateBlocPresentation(
      String featurePath, String snake, String pascal) {
    // BLoC
    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'bloc', '${snake}_bloc.dart'), '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '${snake}_event.dart';
import '${snake}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc() : super(${pascal}Initial()) {
    on<${pascal}Started>(_onStarted);
  }

  Future<void> _onStarted(
    ${pascal}Started event,
    Emitter<${pascal}State> emit,
  ) async {
    emit(${pascal}Loading());
    // Implement your logic here
  }
}
''');

    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'bloc', '${snake}_event.dart'), '''
import 'package:equatable/equatable.dart';

abstract class ${pascal}Event extends Equatable {
  const ${pascal}Event();

  @override
  List<Object> get props => [];
}

class ${pascal}Started extends ${pascal}Event {
  const ${pascal}Started();
}
''');

    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'bloc', '${snake}_state.dart'), '''
import 'package:equatable/equatable.dart';

abstract class ${pascal}State extends Equatable {
  const ${pascal}State();

  @override
  List<Object> get props => [];
}

class ${pascal}Initial extends ${pascal}State {}

class ${pascal}Loading extends ${pascal}State {}

class ${pascal}Success extends ${pascal}State {}

class ${pascal}Failure extends ${pascal}State {
  final String message;
  const ${pascal}Failure(this.message);

  @override
  List<Object> get props => [message];
}
''');

    _generateScreen(featurePath, snake, pascal, 'StatelessWidget');
  }

  void _generateScreen(
      String featurePath, String snake, String pascal, String widgetType) {
    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'screens', '${snake}_screen.dart'),
        '''
import 'package:flutter/material.dart';

class ${pascal}Screen extends StatelessWidget {
  static const String routeName = '/$snake';

  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascal'),
      ),
      body: const Center(
        child: Text('$pascal Screen'),
      ),
    );
  }
}
''');

    // Empty widgets folder
    FsUtils.writeFile(
        p.join(featurePath, 'presentation', 'widgets', '.gitkeep'), '');
  }

  void _registerRoute(String snake, String pascal) {
    if (stateManagement == StateManagement.getx) {
      _registerGetxRoute(snake, pascal);
    } else {
      _registerGoRoute(snake, pascal);
    }
  }

  void _registerGetxRoute(String snake, String pascal) {
    final routesFile = p.join(libPath, 'core', 'routes', 'app_routes.dart');
    final pagesFile = p.join(libPath, 'core', 'routes', 'app_pages.dart');

    // Add to routes
    FsUtils.replaceInFile(
      routesFile,
      '  // Add your routes here',
      '  static const String $snake = \'/$snake\';\n  // Add your routes here',
    );

    // Add to pages
    final screenImport =
        "import '../../features/$snake/presentation/screens/${snake}_screen.dart';";
    final bindingImport =
        "import '../../features/$snake/bindings/${snake}_binding.dart';";
    final pageEntry = '''    GetPage(
      name: AppRoutes.$snake,
      page: () => const ${pascal}Screen(),
      binding: ${pascal}Binding(),
    ),''';

    final content = FsUtils.readFile(pagesFile);
    if (!content.contains(screenImport)) {
      FsUtils.replaceInFile(
        pagesFile,
        "import 'package:get/get.dart';",
        "import 'package:get/get.dart';\n$screenImport\n$bindingImport",
      );
      FsUtils.replaceInFile(
        pagesFile,
        '    // GetPage(',
        '$pageEntry\n    // GetPage(',
      );
    }
  }

  void _registerGoRoute(String snake, String pascal) {
    final routerFile = p.join(libPath, 'core', 'routes', 'app_router.dart');
    final screenImport =
        "import '../../features/$snake/presentation/screens/${snake}_screen.dart';";
    final routeEntry = '''      GoRoute(
        path: '/$snake',
        builder: (context, state) => const ${pascal}Screen(),
      ),''';

    final content = FsUtils.readFile(routerFile);
    if (!content.contains(screenImport)) {
      FsUtils.replaceInFile(
        routerFile,
        "import 'package:go_router/go_router.dart';",
        "import 'package:go_router/go_router.dart';\n$screenImport",
      );
      FsUtils.replaceInFile(
        routerFile,
        '      // GoRoute(',
        '$routeEntry\n      // GoRoute(',
      );
    }
  }

  void _updateDI(String snake, String pascal) {
    final diFile = p.join(libPath, 'core', 'di', 'injection_container.dart');

    final repoImport =
        "import '../../features/$snake/data/repositories/${snake}_repository_impl.dart';";
    final dsImport =
        "import '../../features/$snake/data/datasources/${snake}_remote_datasource.dart';";
    final domainImport =
        "import '../../features/$snake/domain/repositories/${snake}_repository.dart';";

    final registration = '''
  // ${pascal} Feature
  sl.registerLazySingleton<${pascal}RemoteDataSource>(
    () => ${pascal}RemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<${pascal}Repository>(
    () => ${pascal}RepositoryImpl(remoteDataSource: sl()),
  );''';

    final content = FsUtils.readFile(diFile);
    if (!content.contains(repoImport)) {
      FsUtils.replaceInFile(
        diFile,
        "import 'package:get_it/get_it.dart';",
        "import 'package:get_it/get_it.dart';\n$repoImport\n$dsImport\n$domainImport",
      );
      FsUtils.replaceInFile(
        diFile,
        '  // Features — register feature dependencies here',
        '$registration\n  // Features — register feature dependencies here',
      );
    }
  }
}
