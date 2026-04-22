import 'package:path/path.dart' as p;
import 'package:archit/utils/fs_utils.dart';
import 'package:archit/models/project_config.dart';

/// Generates the core architecture layer of a Flutter project.
///
/// Creates the standard clean architecture structure including
/// constants, errors, network layer, usecases, theme, utils, routes, and DI.
class CoreGenerator {
  /// The path to the Flutter project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// Creates a new CoreGenerator.
  ///
  /// Requires the [projectPath] and [config] for the project.
  CoreGenerator(this.projectPath, this.config);

  /// Returns the path to the lib directory.
  String get libPath => p.join(projectPath, 'lib');

  /// Generates all core architecture files.
  ///
  /// This includes constants, errors, network, usecases, theme,
  /// utilities, routes, and dependency injection setup.
  void generate() {
    _generateConstants();
    _generateErrors();
    _generateNetwork();
    _generateUsecases();
    _generateTheme();
    _generateUtils();
    _generateRoutes();
    _generateDI();
  }

  void _generateConstants() {
    FsUtils.writeFile(
        p.join(libPath, 'core', 'constants', 'app_constants.dart'), '''
class AppConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String appName = '${config.name}';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
''');

    FsUtils.writeFile(
        p.join(libPath, 'core', 'constants', 'app_strings.dart'), '''
class AppStrings {
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String noInternet = 'No internet connection';
  static const String retry = 'Retry';
}
''');

    FsUtils.writeFile(
        p.join(libPath, 'core', 'constants', 'app_sizes.dart'), '''
class AppSizes {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
}
''');
  }

  void _generateErrors() {
    FsUtils.writeFile(p.join(libPath, 'core', 'errors', 'failures.dart'), '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
''');

    FsUtils.writeFile(p.join(libPath, 'core', 'errors', 'exceptions.dart'), '''
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}
''');
  }

  void _generateNetwork() {
    FsUtils.writeFile(p.join(libPath, 'core', 'network', 'api_client.dart'), '''
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('[REQUEST] \${options.method} \${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('[RESPONSE] \${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('[ERROR] \${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      return await _dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ServerException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException(message: 'Connection timed out');
      case DioExceptionType.badResponse:
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Server error',
          statusCode: e.response?.statusCode,
        );
      default:
        throw ServerException(message: e.message ?? 'Unknown error');
    }
  }
}
''');

    FsUtils.writeFile(
        p.join(libPath, 'core', 'network', 'network_info.dart'), '''
import 'dart:io';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
''');
  }

  void _generateUsecases() {
    FsUtils.writeFile(p.join(libPath, 'core', 'usecases', 'usecase.dart'), '''
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
''');
  }

  void _generateTheme() {
    FsUtils.writeFile(p.join(libPath, 'core', 'theme', 'app_colors.dart'), '''
import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C96FF);
  static const Color primaryDark = Color(0xFF3D35CC);

  // Secondary
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryDark = Color(0xFF018786);

  // Accent
  static const Color accent = Color(0xFFFF6B6B);

  // Neutrals
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);

  // Dark Mode
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
''');

    FsUtils.writeFile(p.join(libPath, 'core', 'theme', 'app_theme.dart'), '''
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  );
}
''');

    FsUtils.writeFile(
        p.join(libPath, 'core', 'theme', 'app_text_styles.dart'), '''
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading1 = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontSize: 10.sp,
    color: AppColors.textHint,
  );
}
''');
  }

  void _generateUtils() {
    FsUtils.writeFile(p.join(libPath, 'core', 'utils', 'validators.dart'), '''
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r\'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$\');
    if (!emailRegex.hasMatch(value)) return 'Invalid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.isEmpty) return '\$field is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r\'^[\+]?[0-9]{10,14}\$\');
    if (!phoneRegex.hasMatch(value)) return 'Invalid phone number';
    return null;
  }
}
''');

    FsUtils.writeFile(p.join(libPath, 'core', 'utils', 'extensions.dart'), '''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedDate() => DateFormat('dd MMM yyyy').format(this);
  String toFormattedDateTime() => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 0) return '\${diff.inDays}d ago';
    if (diff.inHours > 0) return '\${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '\${diff.inMinutes}m ago';
    return 'Just now';
  }
}

extension StringExtension on String {
  String get capitalize => isEmpty ? '' : this[0].toUpperCase() + substring(1);
  bool get isValidEmail => RegExp(r\'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$\').hasMatch(this);
}

extension NumberExtension on num {
  String get toCurrency => NumberFormat.currency(symbol: '\$').format(this);
  String get toCompact => NumberFormat.compact().format(this);
}
''');

    FsUtils.writeFile(p.join(libPath, 'core', 'utils', 'logger.dart'), '''
import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);
''');
  }

  void _generateRoutes() {
    if (config.stateManagement == StateManagement.getx) {
      _generateGetxRoutes();
    } else {
      _generateGoRoutes();
    }
  }

  void _generateGetxRoutes() {
    FsUtils.writeFile(p.join(libPath, 'core', 'routes', 'app_routes.dart'), '''
abstract class AppRoutes {
  static const String initial = '/';
  // Add your routes here
  // static const String home = '/home';
}
''');

    FsUtils.writeFile(p.join(libPath, 'core', 'routes', 'app_pages.dart'), '''
import 'package:get/get.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    // GetPage(
    //   name: AppRoutes.home,
    //   page: () => const HomeScreen(),
    //   binding: HomeBinding(),
    // ),
  ];
}
''');
  }

  void _generateGoRoutes() {
    FsUtils.writeFile(p.join(libPath, 'core', 'routes', 'app_router.dart'), '''
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // GoRoute(
      //   path: '/',
      //   builder: (context, state) => const HomeScreen(),
      // ),
    ],
  );
}
''');
  }

  void _generateDI() {
    FsUtils.writeFile(p.join(libPath, 'core', 'di', 'injection_container.dart'),
        _getDIContent());
  }

  String _getDIContent() {
    if (config.stateManagement == StateManagement.getx) {
      return '''
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Features — register feature dependencies here
  // await _initFeature();
}
''';
    }

    return '''
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Features — register feature dependencies here
  // await _initFeature();
}
''';
  }
}
