import 'package:flutter/material.dart';
import 'package:securely/securely.dart';

class SecureKeyboardScreen extends StatefulWidget {
  const SecureKeyboardScreen({super.key});

  @override
  State<SecureKeyboardScreen> createState() => _SecureKeyboardScreenState();
}

class _SecureKeyboardScreenState extends State<SecureKeyboardScreen> {
  // Input controllers
  final _bottomSheetController = TextEditingController();
  final _inlineController = TextEditingController();

  // Focus nodes
  final _bottomSheetFocusNode = FocusNode();
  final _inlineFocusNode = FocusNode();

  // Customization configurations
  SecureKeyboardType _keyboardType = SecureKeyboardType.numeric;
  SecureKeyboardShuffle _shuffleType = SecureKeyboardShuffle.none;
  SecureKeyboardObscureMode _obscureMode =
      SecureKeyboardObscureMode.blockKeyboard;

  bool _obscureOnScreenShare = true;
  bool _enableHapticFeedback = true;
  bool _useModalBottomSheet = false;
  bool _isInlineKeyboardVisible = false;
  bool _isBottomSheetKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    // Listen to focus changes for inline demonstration
    _inlineFocusNode.addListener(_onInlineFocusChange);
    _bottomSheetFocusNode.addListener(_onFocusNodeChange);
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _inlineController.dispose();
    _bottomSheetFocusNode.removeListener(_onFocusNodeChange);
    _bottomSheetFocusNode.dispose();
    _inlineFocusNode.removeListener(_onInlineFocusChange);
    _inlineFocusNode.dispose();
    super.dispose();
  }

  void _onFocusNodeChange() {
    setState(() {});
  }

  void _onInlineFocusChange() {
    setState(() {
      _isInlineKeyboardVisible = _inlineFocusNode.hasFocus;
    });
    if (_inlineFocusNode.hasFocus) {
      // Scroll the inline text field into view after the keyboard opens
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _inlineFocusNode.hasFocus) {
          Scrollable.ensureVisible(
            _inlineFocusNode.context!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.5,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  double get _bottomScrollPadding =>
      (_bottomSheetFocusNode.hasFocus || _isBottomSheetKeyboardVisible)
      ? 330.0
      : 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: _bottomScrollPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KEYBOARD CONFIGURATION',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Configuration Card
                  Material(
                    color: const Color(0xFF161626),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type
                          _buildDropdownRow<SecureKeyboardType>(
                            label: 'Keyboard Type',
                            value: _keyboardType,
                            items: SecureKeyboardType.values,
                            displayText: (val) =>
                                val == SecureKeyboardType.numeric
                                ? 'Numeric (Pinpad)'
                                : 'Alphanumeric (Full)',
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _keyboardType = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Shuffle
                          _buildDropdownRow<SecureKeyboardShuffle>(
                            label: 'Shuffle Strategy',
                            value: _shuffleType,
                            items: SecureKeyboardShuffle.values,
                            displayText: (val) {
                              switch (val) {
                                case SecureKeyboardShuffle.none:
                                  return 'Standard (No Shuffle)';
                                case SecureKeyboardShuffle.once:
                                  return 'Shuffle Once (On Load)';
                                case SecureKeyboardShuffle.always:
                                  return 'Shuffle Always (Every Tap)';
                              }
                            },
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _shuffleType = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          // Obscure Mode (Screen Recording)
                          _buildDropdownRow<SecureKeyboardObscureMode>(
                            label: 'Screen Share Protection',
                            value: _obscureMode,
                            items: SecureKeyboardObscureMode.values,
                            displayText: (val) {
                              switch (val) {
                                case SecureKeyboardObscureMode.none:
                                  return 'None (Visible Keys)';
                                case SecureKeyboardObscureMode.obscureLabels:
                                  return 'Obscure Labels (🔒 Keys)';
                                case SecureKeyboardObscureMode.blockKeyboard:
                                  return 'Block Usage (Overlay Shield)';
                              }
                            },
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _obscureMode = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 10),
                          // Switches
                          SwitchListTile(
                            title: const Text(
                              'Obscure Text on Screen Share',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Forces stars/dots when screen is captured',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            value: _obscureOnScreenShare,
                            activeThumbColor: Colors.cyan,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setState(() => _obscureOnScreenShare = val),
                          ),
                          SwitchListTile(
                            title: const Text(
                              'Haptic Key Feedback',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Plays light physical vibration on keypress',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            value: _enableHapticFeedback,
                            activeThumbColor: Colors.cyan,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setState(() => _enableHapticFeedback = val),
                          ),
                          SwitchListTile(
                            title: const Text(
                              'Use Modal Bottom Sheet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Blocks touch interactions outside the keyboard',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            value: _useModalBottomSheet,
                            activeThumbColor: Colors.cyan,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) =>
                                setState(() => _useModalBottomSheet = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'INTERACTIVE TEST BENCH',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Input Demos
                  // Input Demos
                  Material(
                    color: const Color(0xFF161626),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Bottom Sheet Mode',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tapping this field will slide up the secure keyboard in a secure drawer, shielding the native keyboard.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SecureTextField(
                            controller: _bottomSheetController,
                            focusNode: _bottomSheetFocusNode,
                            showKeyboardBottomSheet: true,
                            useModalBottomSheet: _useModalBottomSheet,
                            keyboardType: _keyboardType,
                            keyboardShuffleType: _shuffleType,
                            keyboardObscureMode: _obscureMode,
                            obscureOnScreenShare: _obscureOnScreenShare,
                            enableHapticFeedback: _enableHapticFeedback,
                            onKeyboardVisible: (visible) {
                              setState(() {
                                _isBottomSheetKeyboardVisible = visible;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter secure password',
                              hintStyle: const TextStyle(
                                color: Colors.white24,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E1E2E),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.cyan,
                                size: 20,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white10,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.cyan,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            '2. Inline (Pinned) Mode',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'The keyboard will display inline on the page below the field, perfect for PIN code screens.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SecureTextField(
                            controller: _inlineController,
                            focusNode: _inlineFocusNode,
                            showKeyboardBottomSheet:
                                false, // Turn off auto bottom sheet
                            obscureOnScreenShare: _obscureOnScreenShare,
                            decoration: InputDecoration(
                              hintText: 'Enter transaction PIN',
                              hintStyle: const TextStyle(
                                color: Colors.white24,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1E1E2E),
                              prefixIcon: const Icon(
                                Icons.dialpad,
                                color: Colors.cyan,
                                size: 20,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white10,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.cyan,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 3.0,
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Inline Keyboard Builder (displays when Inline field is focused)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _isInlineKeyboardVisible ? 330.0 : 0.0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _isInlineKeyboardVisible
                  ? SecureKeyboard(
                      controller: _inlineController,
                      type: _keyboardType,
                      shuffleType: _shuffleType,
                      obscureMode: _obscureMode,
                      enableHapticFeedback: _enableHapticFeedback,
                      onDone: () {
                        _inlineFocusNode.unfocus();
                      },
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) displayText,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            child: DropdownButton<T>(
              value: value,
              dropdownColor: const Color(0xFF1E1E2E),
              iconEnabledColor: Colors.cyan,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(displayText(item)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
