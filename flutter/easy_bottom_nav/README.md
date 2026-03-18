# easy_bottom_nav

A lightweight and customizable bottom navigation widget for Flutter.

## Features

- Simple API focused on `items`, `currentIndex`, and `onTap`
- Built on top of Flutter's `BottomNavigationBar`
- Supports icon, active icon, label, tooltip, and style customization

## Installation

```yaml
dependencies:
  easy_bottom_nav: ^0.0.1
```

## Usage

```dart
import 'package:easy_bottom_nav/easy_bottom_nav.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Current tab: $_index')),
      bottomNavigationBar: EasyBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        items: const [
          EasyBottomNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          EasyBottomNavItem(icon: Icon(Icons.search_outlined), label: 'Search'),
          EasyBottomNavItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## Example

A full runnable demo is available in `example/`:

```bash
cd example
flutter run
```

## Testing

```bash
flutter test
```

## License

BSD 3-Clause License. See [LICENSE](LICENSE).
