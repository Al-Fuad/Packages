import 'package:path/path.dart' as p;
import 'package:archit/utils/fs_utils.dart';
import 'package:archit/models/project_config.dart';

/// Generates a new usecase for an existing feature.
///
/// Creates the usecase file and updates the data source,
/// repository interface and implementation, and dependency injection.
class UsecaseGenerator {
  /// The path to the Flutter project.
  final String projectPath;

  /// The state management solution used in the project.
  final StateManagement stateManagement;

  /// Creates a new UsecaseGenerator.
  ///
  /// Requires the [projectPath] and [stateManagement] strategy.
  UsecaseGenerator(this.projectPath, this.stateManagement);

  /// Returns the path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Generates a usecase and wires it through the architecture.
  ///
  /// Creates the usecase file, adds methods to the data source
  /// and repository, and registers it in dependency injection.
  /// Both [featureName] and [usecaseName] should be in snake_case.
  void generateUsecase(String featureName, String usecaseName) {
    final featureSnake = FsUtils.toSnakeCaseSafe(featureName);
    final featurePascal = FsUtils.toPascalCase(featureSnake);
    final usecaseSnake = FsUtils.toSnakeCaseSafe(usecaseName);
    final usecasePascal = FsUtils.toPascalCase(usecaseSnake);

    _generateUsecaseFile(
        featureSnake, featurePascal, usecaseSnake, usecasePascal);
    _addMethodToDataSource(
        featureSnake, featurePascal, usecaseSnake, usecasePascal);
    _addMethodToRepository(
        featureSnake, featurePascal, usecaseSnake, usecasePascal);
    _addMethodToRepositoryImpl(
        featureSnake, featurePascal, usecaseSnake, usecasePascal);
    _registerUsecaseInDI(
        featureSnake, featurePascal, usecaseSnake, usecasePascal);
  }

  void _generateUsecaseFile(String featureSnake, String featurePascal,
      String usecaseSnake, String usecasePascal) {
    final usecasePath = p.join(
      libPath,
      'features',
      featureSnake,
      'domain',
      'usecases',
      '${usecaseSnake}_usecase.dart',
    );

    FsUtils.writeFile(usecasePath, '''
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/${featureSnake}_repository.dart';

class ${usecasePascal}UseCase implements UseCase<void, NoParams> {
  final ${featurePascal}Repository repository;

  ${usecasePascal}UseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.${_toCamelCase(usecaseSnake)}();
  }
}
''');
  }

  void _addMethodToDataSource(String featureSnake, String featurePascal,
      String usecaseSnake, String usecasePascal) {
    final dsPath = p.join(
      libPath,
      'features',
      featureSnake,
      'data',
      'datasources',
      '${featureSnake}_remote_datasource.dart',
    );

    final methodSignature = '  Future<void> ${_toCamelCase(usecaseSnake)}();';
    final methodImpl = '''
  @override
  Future<void> ${_toCamelCase(usecaseSnake)}() async {
    // TODO: implement ${_toCamelCase(usecaseSnake)}
    throw UnimplementedError();
  }''';

    _insertBeforeClosingBrace(dsPath,
        'abstract class ${featurePascal}RemoteDataSource', methodSignature);
    _insertBeforeClosingBrace(
        dsPath, 'class ${featurePascal}RemoteDataSourceImpl', methodImpl);
  }

  void _addMethodToRepository(String featureSnake, String featurePascal,
      String usecaseSnake, String usecasePascal) {
    final repoPath = p.join(
      libPath,
      'features',
      featureSnake,
      'domain',
      'repositories',
      '${featureSnake}_repository.dart',
    );

    final methodSignature =
        '  Future<Either<Failure, void>> ${_toCamelCase(usecaseSnake)}();';
    _insertBeforeClosingBrace(
        repoPath, 'abstract class ${featurePascal}Repository', methodSignature);
  }

  void _addMethodToRepositoryImpl(String featureSnake, String featurePascal,
      String usecaseSnake, String usecasePascal) {
    final repoImplPath = p.join(
      libPath,
      'features',
      featureSnake,
      'data',
      'repositories',
      '${featureSnake}_repository_impl.dart',
    );

    final methodImpl = '''
  @override
  Future<Either<Failure, void>> ${_toCamelCase(usecaseSnake)}() async {
    try {
      await remoteDataSource.${_toCamelCase(usecaseSnake)}();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }''';

    _insertBeforeClosingBrace(
        repoImplPath, 'class ${featurePascal}RepositoryImpl', methodImpl);
  }

  void _registerUsecaseInDI(String featureSnake, String featurePascal,
      String usecaseSnake, String usecasePascal) {
    final diFile = p.join(libPath, 'core', 'di', 'injection_container.dart');
    final usecaseImport =
        "import '../../features/$featureSnake/domain/usecases/${usecaseSnake}_usecase.dart';";

    final registration =
        "  sl.registerLazySingleton(() => ${usecasePascal}UseCase(repository: sl()));";

    final content = FsUtils.readFile(diFile);

    // Add import if not exists
    if (!content.contains(usecaseImport)) {
      FsUtils.replaceInFile(
        diFile,
        "import 'package:get_it/get_it.dart';",
        "import 'package:get_it/get_it.dart';\n$usecaseImport",
      );
    }

    // Add registration in the right feature block
    final featureComment = '  // ${featurePascal} Feature';
    if (content.contains(featureComment)) {
      FsUtils.replaceInFile(
          diFile, featureComment, '$featureComment\n$registration');
    } else {
      FsUtils.replaceInFile(
        diFile,
        '  // Features — register feature dependencies here',
        '$registration\n  // Features — register feature dependencies here',
      );
    }
  }

  /// Insert content before the last closing brace of a specific class
  void _insertBeforeClosingBrace(
      String filePath, String classIdentifier, String content) {
    if (!FsUtils.fileExists(filePath)) return;

    final fileContent = FsUtils.readFile(filePath);
    final classIndex = fileContent.indexOf(classIdentifier);
    if (classIndex == -1) return;

    // Find the opening brace after the class declaration
    int braceCount = 0;
    int insertPos = -1;
    bool started = false;

    for (int i = classIndex; i < fileContent.length; i++) {
      if (fileContent[i] == '{') {
        braceCount++;
        started = true;
      } else if (fileContent[i] == '}') {
        braceCount--;
        if (started && braceCount == 0) {
          insertPos = i;
          break;
        }
      }
    }

    if (insertPos == -1) return;

    final before = fileContent.substring(0, insertPos);
    final after = fileContent.substring(insertPos);

    // Don't add duplicate methods
    if (fileContent.contains(content.trim().split('\n').first.trim())) return;

    final newContent = '$before\n$content\n$after';
    FsUtils.writeFile(filePath, newContent);
  }

  String _toCamelCase(String snake) {
    final parts = snake.split('_');
    if (parts.isEmpty) return snake;
    return parts.first +
        parts.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  }
}
