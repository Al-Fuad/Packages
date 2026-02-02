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
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
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
          ),
        ],
      ),
    );
  }
}
