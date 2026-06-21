import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

class SecureStorageScreen extends StatefulWidget {
  const SecureStorageScreen({super.key});

  @override
  State<SecureStorageScreen> createState() => _SecureStorageScreenState();
}

class _SecureStorageScreenState extends State<SecureStorageScreen> {
  final _securelyStorage = StoreSecurely();
  final _keyController = TextEditingController(text: 'secret_key');
  final _valueController = TextEditingController(text: 'secret_value');
  String _readValue = '';
  SecurelyAlgorithm _selectedAlgorithm = SecurelyAlgorithm.aesGcm;
  SecurelyKeySize _selectedKeySize = SecurelyKeySize.bits256;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SECURE STORAGE CONSOLE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161626),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ALGORITHM', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SecurelyAlgorithm>(
                                  value: _selectedAlgorithm,
                                  dropdownColor: const Color(0xFF1E1E2E),
                                  iconEnabledColor: Colors.cyan,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedAlgorithm = val;
                                        _securelyStorage.setAlgorithm(val);
                                      });
                                    }
                                  },
                                  items: SecurelyAlgorithm.values.map((algo) {
                                    return DropdownMenuItem(
                                      value: algo,
                                      child: Text(algo == SecurelyAlgorithm.aesGcm ? 'AES-GCM' : 'AES-CBC'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KEY SIZE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<SecurelyKeySize>(
                                  value: _selectedKeySize,
                                  dropdownColor: const Color(0xFF1E1E2E),
                                  iconEnabledColor: Colors.cyan,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedKeySize = val;
                                        _securelyStorage.setKeySize(val);
                                      });
                                    }
                                  },
                                  items: SecurelyKeySize.values.map((size) {
                                    return DropdownMenuItem(
                                      value: size,
                                      child: Text(size == SecurelyKeySize.bits256 ? '256-bit' : '128-bit'),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('KEY', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _keyController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E1E2E),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.cyan)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('VALUE (TO WRITE)', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _valueController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E1E2E),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.cyan)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_keyController.text.isEmpty || _valueController.text.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          await _securelyStorage.write(
                            key: _keyController.text,
                            value: _valueController.text,
                          );
                          messenger.showSnackBar(
                            const SnackBar(content: Text('✍️ Value written successfully!'), backgroundColor: Colors.cyan),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('WRITE'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_keyController.text.isEmpty) return;
                          final val = await _securelyStorage.read(key: _keyController.text);
                          setState(() {
                            _readValue = val ?? '[NOT FOUND]';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white10),
                          ),
                        ),
                        child: const Text('READ'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_keyController.text.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final hasKey = await _securelyStorage.containsKey(key: _keyController.text);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(hasKey ? '🔑 Key exists in storage.' : '❌ Key does not exist.'),
                              backgroundColor: hasKey ? Colors.green : Colors.redAccent,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white10),
                          ),
                        ),
                        child: const Text('CONTAINS?'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_keyController.text.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          await _securelyStorage.delete(key: _keyController.text);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('🗑️ Key deleted.'), backgroundColor: Colors.orangeAccent),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E2E),
                          foregroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.orangeAccent, width: 0.5),
                          ),
                        ),
                        child: const Text('DELETE'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _securelyStorage.clear();
                          setState(() {
                            _readValue = '';
                          });
                          messenger.showSnackBar(
                            const SnackBar(content: Text('🧹 Storage cleared completely!'), backgroundColor: Colors.redAccent),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1E2E),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.redAccent, width: 0.5),
                          ),
                        ),
                        child: const Text('CLEAR ALL'),
                      ),
                    ],
                  ),
                  if (_readValue.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),
                    const Text('READ VALUE RESULT:', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        _readValue,
                        style: TextStyle(
                          color: _readValue.startsWith('[') ? Colors.redAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
