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
╔══════════════════════════════════════════════════╗
║             🔨  Archit CLI  v0.0.2               ║
║     Clean Architecture Scaffold Generator        ║
╚══════════════════════════════════════════════════╝

➤  Enter project name: my_shop_app

📱 Select project type:
  1. Application (app)
  2. Package

🖥️  Select target platforms:
  (comma-separated numbers, e.g: 1,2 — or press Enter for all)
  1. Android   2. iOS   3. Web   4. Windows   5. macOS   6. Linux

⚡ Select state management:
  1. Provider
  2. Riverpod
  3. GetX
  4. BLoC

▶  Creating Flutter project...
✔  Dependencies installed!
✔  Project "my_shop_app" created successfully!

──────────────────────────────────────
📦 Features
──────────────────────────────────────
  (No features yet)
──────────────────────────────────────

  1. ➕  Add new feature
  2. 🚪  Exit

→ Add feature: product
✔  Feature "product" created and registered in routes & DI!

──────────────────────────────────────
🧩 Usecases — product
──────────────────────────────────────
  (No usecases yet)
──────────────────────────────────────

  1. ➕  Add new usecase
  2. ⬅️   Back

→ Add usecase: get_products
✔  UseCase "get_products" wired to datasource, repository & DI!
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

| Category | Packages |
|---|---|
| **State Management** | `provider` / `flutter_riverpod` / `get` / `flutter_bloc + bloc` |
| **Routing** | `go_router` (or GetX built-in) |
| **Network** | `dio` |
| **Storage** | `hive`, `hive_flutter`, `flutter_secure_storage` |
| **UI Utilities** | `flutter_screenutil`, `google_fonts`, `flutter_svg`, `cached_network_image` |
| **Animations** | `flutter_animate`, `shimmer`, `loading_animation_widget` |
| **Components** | `flutter_staggered_grid_view`, `flutter_rating_bar`, `google_nav_bar`, `badges`, `awesome_dialog` |
| **Media** | `image_picker`, `url_launcher` |
| **Data** | `equatable`, `dartz`, `intl` |
| **DI** | `get_it` |
| **Logging** | `logger` |

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

## 🛠️ Run from Source (without global install)

```bash
cd archit
dart run bin/archit.dart
```

---

## 🗺️ Roadmap

- [ ] Local datasource generation
- [ ] Unit test file scaffolding
- [ ] Model field definition during generation
- [ ] `archit remove feature <name>` command