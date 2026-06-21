import 'dart:async';
import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

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
  bool _isDebugger = false;
  bool _isRoot = false;
  bool _isEmulator = false;
  bool _isFrida = false;
  bool _isVpn = false;
  bool _isScreenRecording = false;
  bool _isDeveloperMode = false;
  bool _isUsbDebugging = false;

  late StreamSubscription<void> _screenshotSubscription;
  late StreamSubscription<bool> _screenRecordingSubscription;

  final _securelyStorage = StoreSecurely();
  final _keyController = TextEditingController(text: 'secret_key');
  final _valueController = TextEditingController(text: 'secret_value');
  String _readValue = '';
  SecurelyAlgorithm _selectedAlgorithm = SecurelyAlgorithm.aesGcm;
  SecurelyKeySize _selectedKeySize = SecurelyKeySize.bits256;

  @override
  void initState() {
    super.initState();
    _checkAllStatus();

    // Listen to real-time screenshot events
    _screenshotSubscription = Securely.onScreenshot.listen((_) {
      _showWarningDialog(
        title: '📸 Screenshot Detected',
        message: 'Security Alert: A screenshot of this application has been captured!',
      );
    });

    // Listen to real-time screen recording events
    _screenRecordingSubscription = Securely.onScreenRecordingChanged.listen((isRecording) {
      setState(() {
        _isScreenRecording = isRecording;
      });
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
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _checkAllStatus() async {
    final debugger = await Securely.isDebuggerDetected();
    final root = await Securely.isRootDetected();
    final emulator = await Securely.isEmulatorDetected();
    final frida = await Securely.isFridaDetected();
    final vpn = await Securely.isVpnDetected();
    final recording = await Securely.isScreenRecordingDetected();
    final developerMode = await Securely.isDeveloperModeDetected();
    final usbDebugging = await Securely.isUsbDebuggingDetected();

    if (mounted) {
      setState(() {
        _isDebugger = debugger;
        _isRoot = root;
        _isEmulator = emulator;
        _isFrida = frida;
        _isVpn = vpn;
        _isScreenRecording = recording;
        _isDeveloperMode = developerMode;
        _isUsbDebugging = usbDebugging;
      });
    }
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Acknowledge', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasThreat = _isDebugger || _isRoot || _isFrida || _isUsbDebugging;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'SECURELY RASP DEMO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF161626),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _checkAllStatus,
        color: Colors.cyan,
        backgroundColor: const Color(0xFF1E1E2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasThreat
                        ? [Colors.redAccent.withOpacity(0.15), Colors.red.withOpacity(0.05)]
                        : [Colors.cyan.withOpacity(0.15), Colors.blueAccent.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasThreat ? Colors.redAccent.withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      hasThreat ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                      size: 64,
                      color: hasThreat ? Colors.redAccent : Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasThreat ? 'DEVICE COMPROMISED' : 'ENVIRONMENT SECURE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasThreat ? Colors.redAccent : Colors.cyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No active threat vectors found on the host environment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SECURITY METRICS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStatusCard(
                    title: 'Debugger',
                    isActive: _isDebugger,
                    icon: Icons.bug_report_rounded,
                    activeDesc: 'Debugger attached',
                    cleanDesc: 'No debugger attached',
                    isThreat: true,
                  ),
                  _buildStatusCard(
                    title: 'Jailbreak / Root',
                    isActive: _isRoot,
                    icon: Icons.lock_open_rounded,
                    activeDesc: 'Device compromised',
                    cleanDesc: 'Device not rooted',
                    isThreat: true,
                  ),
                  _buildStatusCard(
                    title: 'Frida Framework',
                    isActive: _isFrida,
                    icon: Icons.shield_rounded,
                    activeDesc: 'Frida framework active',
                    cleanDesc: 'Frida not detected',
                    isThreat: true,
                  ),
                  _buildStatusCard(
                    title: 'Emulator / Sim',
                    isActive: _isEmulator,
                    icon: Icons.devices_rounded,
                    activeDesc: 'Running on simulator/emulator',
                    cleanDesc: 'Running on physical device',
                    isThreat: false,
                  ),
                  _buildStatusCard(
                    title: 'VPN Active',
                    isActive: _isVpn,
                    icon: Icons.vpn_lock_rounded,
                    activeDesc: 'VPN connection active',
                    cleanDesc: 'No active VPN connection',
                    isThreat: false,
                  ),
                  _buildStatusCard(
                    title: 'Screen Recording',
                    isActive: _isScreenRecording,
                    icon: Icons.videocam_rounded,
                    activeDesc: 'Screen capture active',
                    cleanDesc: 'Screen not being recorded',
                    isThreat: false,
                  ),
                  _buildStatusCard(
                    title: 'Developer Mode',
                    isActive: _isDeveloperMode,
                    icon: Icons.developer_mode_rounded,
                    activeDesc: 'Developer mode enabled',
                    cleanDesc: 'Developer mode disabled',
                    isThreat: false,
                  ),
                  _buildStatusCard(
                    title: 'USB Debugging',
                    isActive: _isUsbDebugging,
                    icon: Icons.adb_rounded,
                    activeDesc: 'USB debugging enabled',
                    cleanDesc: 'USB debugging disabled',
                    isThreat: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkAllStatus,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('REFRESH STATUS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                            await _securelyStorage.write(
                              key: _keyController.text,
                              value: _valueController.text,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✍️ Value written successfully!'), backgroundColor: Colors.cyan),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('WRITE'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final val = await _securelyStorage.read(key: _keyController.text);
                            setState(() {
                              _readValue = val ?? '[NOT FOUND]';
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white10))),
                          child: const Text('READ'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final hasKey = await _securelyStorage.containsKey(key: _keyController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(hasKey ? '🔑 Key exists in storage.' : '❌ Key does not exist.'),
                                  backgroundColor: hasKey ? Colors.green : Colors.redAccent,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white10))),
                          child: const Text('CONTAINS?'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _securelyStorage.delete(key: _keyController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🗑️ Key deleted.'), backgroundColor: Colors.orangeAccent),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E), foregroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.orangeAccent, width: 0.5))),
                          child: const Text('DELETE'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await _securelyStorage.clear();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🧹 Storage cleared completely!'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E2E), foregroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.redAccent, width: 0.5))),
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
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required bool isActive,
    required IconData icon,
    required String activeDesc,
    required String cleanDesc,
    required bool isThreat,
  }) {
    Color statusColor;
    String statusText;

    if (isActive) {
      statusColor = isThreat ? Colors.redAccent : Colors.orangeAccent;
      statusText = isThreat ? 'DETECTED' : 'ACTIVE';
    } else {
      statusColor = Colors.greenAccent;
      statusText = 'CLEAN';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 28, color: statusColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isActive ? activeDesc : cleanDesc,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
