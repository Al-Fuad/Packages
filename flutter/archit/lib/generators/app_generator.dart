import 'package:path/path.dart' as p;
import '../utils/fs_utils.dart';
import '../models/project_config.dart';

/// Generates the app entry points (main.dart and app.dart).
///
/// Creates the main.dart file with appropriate initialization
/// and app.dart with routing configuration based on state management.
class AppGenerator {
  /// The path to the Flutter project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// Creates a new AppGenerator.
  ///
  /// Requires the [projectPath] and [config] for the project.
  AppGenerator(this.projectPath, this.config);

  /// Returns the path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Generates the main.dart and app.dart files.
  ///
  /// The generated files include appropriate imports and setup
  /// based on the configured state management solution.
  void generate() {
    _generateMain();
    _generateApp();
  }

  void _generateMain() {
    final sm = config.stateManagement;
    String imports = '';
    String setup = '';

    switch (sm) {
      case StateManagement.provider:
        imports = "import 'package:provider/provider.dart';";
        setup = '';
        break;
      case StateManagement.riverpod:
        imports = "import 'package:flutter_riverpod/flutter_riverpod.dart';";
        setup = '';
        break;
      case StateManagement.getx:
        imports = "import 'package:get/get.dart';";
        setup = '';
        break;
      case StateManagement.bloc:
        imports = '';
        setup = '';
        break;
    }

    FsUtils.writeFile(p.join(libPath, 'main.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
$imports
import 'core/di/injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await di.initDependencies();
  $setup
  runApp(${_getAppWrapper()});
}
''');
  }

  String _getAppWrapper() {
    switch (config.stateManagement) {
      case StateManagement.riverpod:
        return 'const ProviderScope(child: MyApp())';
      default:
        return 'const MyApp()';
    }
  }

  void _generateApp() {
    final sm = config.stateManagement;

    switch (sm) {
      case StateManagement.getx:
        _generateGetxApp();
        break;
      case StateManagement.provider:
        _generateProviderApp();
        break;
      case StateManagement.riverpod:
        _generateRiverpodApp();
        break;
      case StateManagement.bloc:
        _generateBlocApp();
        break;
    }
  }

  void _generateGetxApp() {
    FsUtils.writeFile(p.join(libPath, 'app.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: '${config.name}',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.initial,
          getPages: AppPages.pages,
        );
      },
    );
  }
}
''');
  }

  void _generateProviderApp() {
    FsUtils.writeFile(p.join(libPath, 'app.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '${config.name}',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
''');
  }

  void _generateRiverpodApp() {
    FsUtils.writeFile(p.join(libPath, 'app.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '${config.name}',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
''');
  }

  void _generateBlocApp() {
    FsUtils.writeFile(p.join(libPath, 'app.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: '${config.name}',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
''');
  }
}
