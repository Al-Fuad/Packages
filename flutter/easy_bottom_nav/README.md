# easy_bottom_nav

A very small, customizable and responsive navigation helper for Flutter.

This package exposes a simple `EasyBottomNav` class that maintains a list
of labels and reports taps back to the host widget. It is meant to serve as
a lightweight building block for applications that need a bottom
navigation bar without bringing in a heavy widget library.

---

## 🧩 Features

- Compact API with only three properties (`items`, `currentIndex`, `onTap`).
- No dependencies outside of Flutter itself.
- Easy to integrate into any `StatefulWidget`.

---

## 🚀 Getting Started

### Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  easy_bottom_nav:
    path: ../  # or the hosted version when published
```

Then run:

```bash
flutter pub get
```

> 📌 **Note:** The example directory contains a minimal app demonstrating
> how to wire up the navigation class.

### Basic Usage

Import the library and create an instance of `EasyBottomNav` from within your
widget tree. The widget itself is not provided – this package merely
defines the data structure and behavior, so you can couple it with any
UI of your choosing (e.g. a `BottomNavigationBar`, custom layout, etc.).

```dart
import 'package:easy_bottom_nav/easy_bottom_nav.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  late EasyBottomNav _nav;

  @override
  void initState() {
    super.initState();
    _nav = EasyBottomNav(
      items: ['Home', 'Search', 'Profile'],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Selected: \\${_nav.items[_nav.currentIndex]}')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _nav.currentIndex,
        items: _nav.items
            .map((label) => BottomNavigationBarItem(
                  icon: Icon(Icons.circle),
                  label: label,
                ))
            .toList(),
        onTap: _nav.handleTap,
      ),
    );
  }
}
```

### Running the Example

Navigate to the example folder and launch the app with Flutter:

```bash
cd example
flutter run
```

---

## 🧪 Testing

The `test/` directory currently contains the skeleton for unit tests. You
can add your own validations and run them with:

```bash
flutter test
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull
requests. Please follow the [Dart code style](https://dart.dev/guides/language/effective-dart/style)
and include tests for any new functionality.

---

## 📄 License

This project is licensed under the terms of the [BSD](LICENSE) license.
