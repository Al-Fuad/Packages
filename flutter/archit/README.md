# 🔨 Archit CLI

A powerful command-line tool that scaffolds Flutter projects following **Clean Architecture** principles — with automatic feature generation, usecase wiring, routing, and dependency injection.

---

## ✅ Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- Dart SDK (comes with Flutter)

```bash
flutter --version
dart --version
```

---

## 📦 Installation

```bash
dart pub global activate archit

export PATH="$PATH:$HOME/.pub-cache/bin"
source ~/.zshrc
```

---

## 🚀 Usage

### Create a new Flutter project

```bash
cd ~/projects
archit
```

### Use inside an existing Flutter project

```bash
cd my_flutter_app
archit
```

> When run inside an existing Flutter project root, Archit skips project creation and goes straight to the Feature Manager.

---

## 🎬 Interactive Flow

```

░▒▓███████████████████████████████████████████████████████████████████████████████▓▒░

  ░▒▓  █████╗ ██████╗  ██████╗██╗  ██╗██╗████████╗     ██████╗██╗     ██╗  ▓▒░
  ░▒▓ ██╔══██╗██╔══██╗██╔════╝██║  ██║██║╚══██╔══╝    ██╔════╝██║     ██║  ▓▒░
  ░▒▓ ███████║██████╔╝██║     ███████║██║   ██║       ██║     ██║     ██║  ▓▒░
  ░▒▓ ██╔══██║██╔══██╗██║     ██╔══██║██║   ██║       ██║     ██║     ██║  ▓▒░
  ░▒▓ ██║  ██║██║  ██║╚██████╗██║  ██║██║   ██║       ╚██████╗███████╗██║  ▓▒░
  ░▒▓ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝        ╚═════╝╚══════╝╚═╝  ▓▒░

░▒▓███████████████████████████████████████████████████████████████████████████████▓▒░
╔────────────────────────────────────────────────────────────────────────────────────╗
║  ARCHIT CLI  │  v0.1.0  │  ARCH-GEN  │  DART                                       ║
╚────────────────────────────────────────────────────────────────────────────────────╝
░▒▓███████████████████████████████████████████████████████████████████████████████▓▒░

  > INITIALIZING SCAFFOLD ENGINE .......... OK
  > LOADING ARCHITECTURE MODULES .......... OK
  > MOUNTING FEATURE REGISTRY    .......... OK
  > SYSTEM READY                 .......... OK

  [ >> ]  No Flutter project found in current directory.

  $ Enter project name (snake_case) › hello_archit

  ┌─[ 📱 Select project type: ]
✔  · Application (app)                                                                                                                                                                        

  ┌─[ 🖥️  Select target platforms: ]
✔  · Android, iOS, Web, Windows, macOS, Linux                                                                                                                                                 

  ┌─[ ⚡ Select state management: ]
✔  · BLoC                                                                                                                                                                                     
  ───────────────────────────────────────────────────────────────────────────

  ▶  Creating Flutter project...
  [ >> ]  Running: flutter create hello_archit

  [ OK ]  Flutter project created!
  [ >> ]  Writing pubspec.yaml with pre-configured packages...
  [ >> ]  Generating core architecture...
  [ >> ]  Generating app entry points...
  [ >> ]  Running flutter pub get...

  [ OK ]  Dependencies installed!
  ───────────────────────────────────────────────────────────────────────────

  [ OK ]  Project "hello_archit" created successfully!
  [ >> ]  State Management: BLoC
  [ >> ]  Platforms: android, ios, web, windows, macos, linux
  ───────────────────────────────────────────────────────────────────────────

┌─[ FEATURE REGISTRY ]──────────────────────────────────────────────────────┐
│    [ no features registered yet ]                                         │
└───────────────────────────────────────────────────────────────────────────┘
  Feature Manager
  ❯ ➕  Add new feature
    🚪  Exit

  $ Feature name  (e.g. user_profile, auth) › auth

  ▶  Generating feature: auth...

  [ OK ]  Feature "auth" created and registered in routes & DI!

┌─[ FEATURE REGISTRY ]──────────────────────────────────────────────────────┐
│  01  │  auth                                                              │
└───────────────────────────────────────────────────────────────────────────┘
  Feature Manager
    📁  auth
  ❯ ➕  Add new feature
    🚪  Exit

  $ Feature name  (e.g. user_profile, auth) › home

  ▶  Generating feature: home...

  [ OK ]  Feature "home" created and registered in routes & DI!

┌─[ FEATURE REGISTRY ]──────────────────────────────────────────────────────┐
│  01  │  auth                                                              │
│  02  │  home                                                              │
└───────────────────────────────────────────────────────────────────────────┘
  Feature Manager
  ❯ 📁  auth
    📁  home
    ➕  Add new feature
    🚪  Exit


┌─[ USECASES  ›  auth ]─────────────────────────────────────────────────────┐
│    [ no usecases registered yet ]                                         │
└───────────────────────────────────────────────────────────────────────────┘
  Feature: auth
  ❯ ➕  Add new usecase
    ⬅️   Back

  $ Usecase name  (e.g. get_user, login, fetch_products) › login

  ▶  Generating usecase: login...

  [ OK ]  UseCase "login" wired to datasource, repository & DI!

┌─[ USECASES  ›  auth ]─────────────────────────────────────────────────────┐
│  01  │  login                                                             │
└───────────────────────────────────────────────────────────────────────────┘
  Feature: auth
    🧩  login
  ❯ ➕  Add new usecase
    ⬅️   Back

  $ Usecase name  (e.g. get_user, login, fetch_products) › sign_up

  ▶  Generating usecase: sign_up...

  [ OK ]  UseCase "sign_up" wired to datasource, repository & DI!

┌─[ USECASES  ›  auth ]─────────────────────────────────────────────────────┐
│  01  │  login                                                             │
│  02  │  sign_up                                                           │
└───────────────────────────────────────────────────────────────────────────┘
  Feature: auth
    🧩  login
    🧩  sign_up
    ➕  Add new usecase
  ❯ ⬅️   Back


┌─[ FEATURE REGISTRY ]──────────────────────────────────────────────────────┐
│  01  │  auth                                                              │
│  02  │  home                                                              │
└───────────────────────────────────────────────────────────────────────────┘
  Feature Manager
    📁  auth
    📁  home
    ➕  Add new feature
  ❯ 🚪  Exit

  [ >> ]  Goodbye! Happy coding 🚀
```

---

## 📁 Generated Project Structure

### Provider / Riverpod / BLoC

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # Base URL, timeouts, app name
│   │   ├── app_strings.dart         # Reusable text strings
│   │   └── app_sizes.dart           # Padding, radius, icon size tokens
│   ├── di/
│   │   └── injection_container.dart # GetIt DI — auto-updated on feature/usecase add
│   ├── errors/
│   │   ├── failures.dart            # ServerFailure, CacheFailure, NetworkFailure
│   │   └── exceptions.dart          # ServerException, CacheException
│   ├── network/
│   │   ├── api_client.dart          # Dio client with interceptors & auth token support
│   │   └── network_info.dart        # Internet connectivity check
│   ├── routes/
│   │   └── app_router.dart          # GoRouter — auto-updated when features are added
│   ├── theme/
│   │   ├── app_colors.dart          # Full color palette (light/dark/gradients)
│   │   ├── app_theme.dart           # Material 3 light & dark ThemeData
│   │   └── app_text_styles.dart     # Responsive text styles (ScreenUtil)
│   ├── usecases/
│   │   └── usecase.dart             # Abstract UseCase<Type, Params> base class
│   └── utils/
│       ├── extensions.dart          # Context, DateTime, String, Number extensions
│       ├── validators.dart          # Email, password, phone, required validators
│       └── logger.dart              # Pretty Logger instance
├── features/
│   └── product/                     # Example feature
│       ├── data/
│       │   ├── datasources/
│       │   │   └── product_remote_datasource.dart
│       │   ├── models/
│       │   │   └── product_model.dart     # JSON serialization + fromEntity
│       │   └── repositories/
│       │       └── product_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── product_entity.dart    # Pure Dart, Equatable
│       │   ├── repositories/
│       │   │   └── product_repository.dart  # Abstract contract
│       │   └── usecases/
│       │       └── get_products_usecase.dart  # Auto-generated ✨
│       └── presentation/
│           ├── providers/           # ChangeNotifier (Provider) or StateNotifier (Riverpod)
│           ├── screens/             # product_screen.dart
│           └── widgets/
├── main.dart                        # Configured per state management
└── app.dart                         # MaterialApp.router + ScreenUtil + Theme
```

### GetX

```
lib/
├── core/
│   ├── routes/
│   │   ├── app_routes.dart          # Route name constants
│   │   └── app_pages.dart           # GetPage list — auto-updated
│   └── ...same as above
├── features/
│   └── product/
│       ├── data/ / domain/          # Same as above
│       ├── presentation/
│       │   ├── controllers/
│       │   │   └── product_controller.dart   # GetxController with Rx state
│       │   ├── screens/
│       │   └── widgets/
│       └── bindings/
│           └── product_binding.dart   # Auto-generated & registered ✨
```

---

## 📦 Pre-installed Packages


| Category             | Packages                                                                                          |
| -------------------- | ------------------------------------------------------------------------------------------------- |
| **State Management** | `provider` / `flutter_riverpod` / `get` / `flutter_bloc + bloc`                                   |
| **Routing**          | `go_router` (or GetX built-in)                                                                    |
| **Network**          | `dio`                                                                                             |
| **Storage**          | `hive`, `hive_flutter`, `flutter_secure_storage`                                                  |
| **UI Utilities**     | `flutter_screenutil`, `google_fonts`, `flutter_svg`, `cached_network_image`                       |
| **Animations**       | `flutter_animate`, `shimmer`, `loading_animation_widget`                                          |
| **Components**       | `flutter_staggered_grid_view`, `flutter_rating_bar`, `google_nav_bar`, `badges`, `awesome_dialog` |
| **Media**            | `image_picker`, `url_launcher`                                                                    |
| **Data**             | `equatable`, `dartz`, `intl`                                                                      |
| **DI**               | `get_it`                                                                                          |
| **Logging**          | `logger`                                                                                          |


---

## ✨ What Gets Auto-Wired

When you add a **feature**:

- ✅ Full Clean Architecture folder structure created
- ✅ Route registered in GoRouter / GetX AppPages
- ✅ DataSource, Repository contract & implementation scaffolded
- ✅ Presentation layer generated (Provider / Riverpod / GetxController / BLoC)
- ✅ GetX Binding created and registered (GetX only)
- ✅ GetIt DI entries added automatically

When you add a **usecase**:

- ✅ `UseCase` class created in `domain/usecases/`
- ✅ Method signature added to repository interface
- ✅ Method implementation added to repository impl
- ✅ Method stub added to remote data source
- ✅ UseCase registered in GetIt injection container

---

## 🗺️ Roadmap

- Local datasource generation
- Unit test file scaffolding
- Model field definition during generation
- Remove command

