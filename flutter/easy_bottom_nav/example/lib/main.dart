import 'package:easy_bottom_nav/easy_bottom_nav.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'easy_bottom_nav Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabContent(
      title: 'Home',
      subtitle: 'Welcome to easy_bottom_nav',
      icon: Icons.home_rounded,
    ),
    _TabContent(
      title: 'Search',
      subtitle: 'Find things quickly',
      icon: Icons.search_rounded,
    ),
    _TabContent(
      title: 'Profile',
      subtitle: 'Manage your account',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('easy_bottom_nav Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 64),
            const SizedBox(height: 16),
            Text(tab.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(tab.subtitle),
          ],
        ),
      ),
      bottomNavigationBar: EasyBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          EasyBottomNavItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          EasyBottomNavItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          EasyBottomNavItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TabContent {
  const _TabContent({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
