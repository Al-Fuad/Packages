import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Securely Example App')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                bool debuggerDetected = await Securely.isDebuggerDetected();
                String message = debuggerDetected
                    ? '❌ Debugger is detected!'
                    : '✅ No debugger detected.';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(message),
                    ),
                  ),
                );
              },
              child: const Text('Check Debugger Status'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                bool rootDetected = await Securely.isRootDetected();
                String message = rootDetected
                    ? '❌ Root is detected!'
                    : '✅ No root detected.';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(message),
                    ),
                  ),
                );
              },
              child: const Text('Check Root Status'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                bool emulatorDetected = await Securely.isEmulatorDetected();
                String message = emulatorDetected
                    ? '❌ Emulator is detected!'
                    : '✅ No emulator detected.';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(message),
                    ),
                  ),
                );
              },
              child: const Text('Check Emulator Status'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                bool fridaDetected = await Securely.isFridaDetected();
                String message = fridaDetected
                    ? '❌ Frida is detected!'
                    : '✅ No Frida detected.';
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(message),
                    ),
                  ),
                );
              },
              child: const Text('Check Frida Status'),
            ),
          ],
        ),
      ),
    );
  }
}
