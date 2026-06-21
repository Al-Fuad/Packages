import 'dart:async';
import 'package:flutter/material.dart';
import 'package:securely/securely.dart';
import 'screens/detectors_screen.dart';
import 'screens/secure_storage_screen.dart';
import 'screens/secure_keyboard_screen.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  late StreamSubscription<void> _screenshotSubscription;
  late StreamSubscription<bool> _screenRecordingSubscription;

  // The 3 screens
  final List<Widget> _screens = const [
    DetectorsScreen(),
    SecureStorageScreen(),
    SecureKeyboardScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Listen to real-time screenshot events globally
    _screenshotSubscription = Securely.onScreenshot.listen((_) {
      _showWarningDialog(
        title: '📸 Screenshot Detected',
        message: 'Security Alert: A screenshot of this application has been captured!',
      );
    });

    // Listen to real-time screen recording events globally
    _screenRecordingSubscription = Securely.onScreenRecordingChanged.listen((isRecording) {
      if (!mounted) return;
      if (isRecording) {
        _showWarningDialog(
          title: '🎥 Screen Recording Started',
          message: 'Security Alert: Your screen is currently being recorded or cast!',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Screen recording has stopped.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _screenshotSubscription.cancel();
    _screenRecordingSubscription.cancel();
    super.dispose();
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ACKNOWLEDGE', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'SECURELY RASP DEMO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF161626),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            height: 1.0,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF161626),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white38,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield, color: Colors.cyanAccent),
              label: 'Detectors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage_outlined),
              activeIcon: Icon(Icons.storage, color: Colors.cyanAccent),
              label: 'StoreSecurely',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_alt_outlined),
              activeIcon: Icon(Icons.keyboard_alt, color: Colors.cyanAccent),
              label: 'SecureKeyboard',
            ),
          ],
        ),
      ),
    );
  }
}
