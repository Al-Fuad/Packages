import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:securely/securely.dart';

/// Defines the layout type of the [SecureKeyboard].
enum SecureKeyboardType {
  /// A 4x3 keypad containing numeric digits (0-9).
  numeric,

  /// A QWERTY-based alphanumeric keyboard with letters, numbers, and symbols.
  alphanumeric,
}

/// Defines the key scrambling/shuffling strategy.
enum SecureKeyboardShuffle {
  /// Keys are in their normal, standardized positions.
  none,

  /// Keys are randomized once when the keyboard is initialized/displayed.
  once,

  /// Keys are randomized after every character press.
  always,
}

/// Defines the keyboard's behavior when a screen share or screen recording is active.
enum SecureKeyboardObscureMode {
  /// No special treatment is applied during screen sharing.
  none,

  /// Replaces the key labels with padlocks `🔒` or dots `•` but still registers taps.
  obscureLabels,

  /// Blocks keyboard usage entirely with a secure overlay, preventing any interaction.
  blockKeyboard,
}

/// Customization theme for the [SecureKeyboard].
class SecureKeyboardTheme {
  /// The background color of the keyboard container.
  final Color backgroundColor;

  /// The background color of standard character keys.
  final Color keyBackgroundColor;

  /// The background color of action keys (e.g. Backspace, Shift, Done, Symbols).
  final Color actionKeyBackgroundColor;

  /// Text style for standard character keys.
  final TextStyle textStyle;

  /// Text style for action keys.
  final TextStyle actionTextStyle;

  /// Border radius of the keys.
  final double keyBorderRadius;

  /// Border of the individual keys.
  final Border? keyBorder;

  /// Border of the keyboard container.
  final Border? keyboardBorder;

  /// Box shadows applied to each key.
  final List<BoxShadow>? keyShadow;

  /// Margin around the keyboard container.
  final EdgeInsetsGeometry keyboardPadding;

  /// Height of the keyboard.
  final double height;

  /// The background color of the header bar.
  final Color? headerBackgroundColor;

  /// The text style of the header label.
  final TextStyle headerTextStyle;

  /// Whether to show the header bar with Done and Status label.
  final bool showHeader;

  /// Text to show in the header.
  final String headerText;

  const SecureKeyboardTheme({
    this.backgroundColor = const Color(0xFF12121E),
    this.keyBackgroundColor = const Color(0xFF1C1C2E),
    this.actionKeyBackgroundColor = const Color(0xFF25253A),
    this.textStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    this.actionTextStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.cyanAccent,
    ),
    this.keyBorderRadius = 8.0,
    this.keyBorder,
    this.keyboardBorder,
    this.keyShadow = const [
      BoxShadow(
        color: Colors.black26,
        offset: Offset(0, 2),
        blurRadius: 4,
      ),
    ],
    this.keyboardPadding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
    this.height = 330.0,
    this.headerBackgroundColor,
    this.headerTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white38,
      letterSpacing: 0.8,
    ),
    this.showHeader = true,
    this.headerText = '🔒 SECURE ENTRY',
  });
}

/// A highly secure, customizable, in-app keyboard.
class SecureKeyboard extends StatefulWidget {
  /// The controller of the text field this keyboard is typing into.
  final TextEditingController controller;

  /// The keyboard layout type (numeric or alphanumeric).
  final SecureKeyboardType type;

  /// Key scrambling configuration.
  final SecureKeyboardShuffle shuffleType;

  /// Behavior when screen recording/sharing is active.
  final SecureKeyboardObscureMode obscureMode;

  /// Callback triggered when the 'Done' or checkmark key is pressed.
  final VoidCallback? onDone;

  /// Theme customization of the keyboard.
  final SecureKeyboardTheme theme;

  /// Whether to play a light haptic impact on key taps.
  final bool enableHapticFeedback;

  const SecureKeyboard({
    super.key,
    required this.controller,
    this.type = SecureKeyboardType.numeric,
    this.shuffleType = SecureKeyboardShuffle.none,
    this.obscureMode = SecureKeyboardObscureMode.blockKeyboard,
    this.onDone,
    this.theme = const SecureKeyboardTheme(),
    this.enableHapticFeedback = true,
  });

  @override
  State<SecureKeyboard> createState() => _SecureKeyboardState();
}

class _SecureKeyboardState extends State<SecureKeyboard> {
  // Screen recording state variables
  bool _isScreenRecording = false;
  StreamSubscription<bool>? _screenRecordingSubscription;

  // Key layouts
  late List<String> _numbers; // For numeric (0-9)
  late List<String> _letters; // For alphanumeric (a-z)

  // Sub-states for alphanumeric keyboard
  bool _isShiftEnabled = false;
  bool _isSymbolsPageActive = false;

  // Constants for alphanumeric
  static const List<String> _defaultLetters = [
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
    'z', 'x', 'c', 'v', 'b', 'n', 'm',
  ];

  static const List<String> _symbolsPage1 = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    '-', '/', ':', ';', '(', ')', '\$', '&', '@', '"',
    '.', ',', '?', '!', '\'',
  ];

  @override
  void initState() {
    super.initState();
    _initializeKeys();
    _setupScreenRecordingProtection();
  }

  @override
  void dispose() {
    _screenRecordingSubscription?.cancel();
    super.dispose();
  }

  void _initializeKeys() {
    _numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _letters = List.from(_defaultLetters);

    if (widget.shuffleType == SecureKeyboardShuffle.once ||
        widget.shuffleType == SecureKeyboardShuffle.always) {
      _shuffleKeys();
    }
  }

  void _shuffleKeys() {
    final rand = math.Random();
    // Shuffle numbers
    for (int i = _numbers.length - 1; i > 0; i--) {
      int j = rand.nextInt(i + 1);
      final temp = _numbers[i];
      _numbers[i] = _numbers[j];
      _numbers[j] = temp;
    }
    // Shuffle letters
    for (int i = _letters.length - 1; i > 0; i--) {
      int j = rand.nextInt(i + 1);
      final temp = _letters[i];
      _letters[i] = _letters[j];
      _letters[j] = temp;
    }
  }

  Future<void> _setupScreenRecordingProtection() async {
    try {
      final isEmulator = await Securely.isEmulatorDetected();
      if (isEmulator) return; // Bypass screen recording blocks on emulators/simulators for testing
    } catch (_) {}

    // Initial check
    try {
      final recording = await Securely.isScreenRecordingDetected();
      if (mounted) {
        setState(() {
          _isScreenRecording = recording;
        });
      }
    } catch (_) {
      // Fallback
    }

    // Real-time stream
    _screenRecordingSubscription = Securely.onScreenRecordingChanged.listen((recording) {
      if (mounted) {
        setState(() {
          _isScreenRecording = recording;
        });
      }
    });
  }

  void _onKeyTap(String value) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Insert character respecting current text selection cursor
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, value);
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + value.length),
    );

    // Reshuffle if "always" shuffle is set
    if (widget.shuffleType == SecureKeyboardShuffle.always) {
      setState(() {
        _shuffleKeys();
      });
    }
  }

  void _onBackspaceTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (!selection.isValid || text.isEmpty) return;

    final start = selection.start;
    final end = selection.end;

    if (start == end) {
      if (start == 0) return;
      final newText = text.replaceRange(start - 1, start, '');
      widget.controller.value = widget.controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    } else {
      final newText = text.replaceRange(start, end, '');
      widget.controller.value = widget.controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    }

    if (widget.shuffleType == SecureKeyboardShuffle.always) {
      setState(() {
        _shuffleKeys();
      });
    }
  }

  void _onClearTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.controller.clear();
    if (widget.shuffleType == SecureKeyboardShuffle.always) {
      setState(() {
        _shuffleKeys();
      });
    }
  }

  void _onDoneTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    if (widget.onDone != null) {
      widget.onDone!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen obscuring state
    final isBlocked = _isScreenRecording &&
        widget.obscureMode == SecureKeyboardObscureMode.blockKeyboard;
    final isLabelsObscured = _isScreenRecording &&
        widget.obscureMode == SecureKeyboardObscureMode.obscureLabels;

    return TextFieldTapRegion(
      child: Container(
        height: widget.theme.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.theme.backgroundColor,
          border: widget.theme.keyboardBorder,
        ),
        padding: widget.theme.keyboardPadding,
        child: Stack(
        children: [
          // Keyboard body
          Positioned.fill(
            child: Opacity(
              opacity: isBlocked ? 0.05 : 1.0,
              child: IgnorePointer(
                ignoring: isBlocked,
                child: Column(
                  children: [
                    if (widget.theme.showHeader) ...[
                      _buildHeader(),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: widget.type == SecureKeyboardType.numeric
                          ? _buildNumericKeyboard(isLabelsObscured)
                          : _buildAlphanumericKeyboard(isLabelsObscured),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shield Overlay for block mode
          if (isBlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.theme.backgroundColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'SECURE INPUT BLOCKED',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Screen recording or casting is active.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  // ================= NUMERIC LAYOUT =================

  Widget _buildNumericKeyboard(bool obscureLabels) {
    // Prepare rows
    // Row 1: [1, 2, 3]
    // Row 2: [4, 5, 6]
    // Row 3: [7, 8, 9]
    // Row 4: [Clear, 0, Backspace]
    final row1 = _numbers.sublist(0, 3);
    final row2 = _numbers.sublist(3, 6);
    final row3 = _numbers.sublist(6, 9);
    final zeroChar = _numbers[9];

    return Column(
      children: [
        Expanded(child: _buildNumericRow(row1, obscureLabels)),
        const SizedBox(height: 8),
        Expanded(child: _buildNumericRow(row2, obscureLabels)),
        const SizedBox(height: 8),
        Expanded(child: _buildNumericRow(row3, obscureLabels)),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              // Clear action key
              Expanded(
                child: _buildKeyButton(
                  label: 'Clear',
                  isAction: true,
                  onTap: _onClearTap,
                ),
              ),
              const SizedBox(width: 8),
              // 0 digit key
              Expanded(
                child: _buildKeyButton(
                  label: zeroChar,
                  isAction: false,
                  obscure: obscureLabels,
                  onTap: () => _onKeyTap(zeroChar),
                ),
              ),
              const SizedBox(width: 8),
              // Backspace action key
              Expanded(
                child: _buildKeyButton(
                  label: '⌫',
                  isAction: true,
                  onTap: _onBackspaceTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumericRow(List<String> values, bool obscureLabels) {
    return Row(
      children: values.map((val) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildKeyButton(
              label: val,
              isAction: false,
              obscure: obscureLabels,
              onTap: () => _onKeyTap(val),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= ALPHANUMERIC LAYOUT =================

  Widget _buildAlphanumericKeyboard(bool obscureLabels) {
    if (_isSymbolsPageActive) {
      return _buildSymbolsKeyboard(obscureLabels);
    }

    // Normal Letter layout
    // Row 1: q w e r t y u i o p
    // Row 2: a s d f g h j k l
    // Row 3: Shift z x c v b n m Backspace
    // Row 4: ?123 [Space] Done
    final r1 = _letters.sublist(0, 10);
    final r2 = _letters.sublist(10, 19);
    final r3 = _letters.sublist(19, 26);

    return Column(
      children: [
        // Row 1
        Expanded(
          child: Row(
            children: r1.map((char) {
              final formattedChar = _isShiftEnabled ? char.toUpperCase() : char.toLowerCase();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildKeyButton(
                    label: formattedChar,
                    isAction: false,
                    obscure: obscureLabels,
                    onTap: () {
                      _onKeyTap(formattedChar);
                      // Disable temporary shift if active
                      if (_isShiftEnabled) {
                        setState(() {
                          _isShiftEnabled = false;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Row 2
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: r2.map((char) {
                final formattedChar = _isShiftEnabled ? char.toUpperCase() : char.toLowerCase();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildKeyButton(
                      label: formattedChar,
                      isAction: false,
                      obscure: obscureLabels,
                      onTap: () {
                        _onKeyTap(formattedChar);
                        if (_isShiftEnabled) {
                          setState(() {
                            _isShiftEnabled = false;
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Row 3
        Expanded(
          child: Row(
            children: [
              // Shift key
              Expanded(
                flex: 15,
                child: _buildKeyButton(
                  label: _isShiftEnabled ? '⬆' : '⇧',
                  isAction: true,
                  isSelected: _isShiftEnabled,
                  onTap: () {
                    setState(() {
                      _isShiftEnabled = !_isShiftEnabled;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              ...r3.map((char) {
                final formattedChar = _isShiftEnabled ? char.toUpperCase() : char.toLowerCase();
                return Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildKeyButton(
                      label: formattedChar,
                      isAction: false,
                      obscure: obscureLabels,
                      onTap: () {
                        _onKeyTap(formattedChar);
                        if (_isShiftEnabled) {
                          setState(() {
                            _isShiftEnabled = false;
                          });
                        }
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Backspace
              Expanded(
                flex: 15,
                child: _buildKeyButton(
                  label: '⌫',
                  isAction: true,
                  onTap: _onBackspaceTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Row 4
        Expanded(
          child: Row(
            children: [
              // Toggle symbols
              Expanded(
                flex: 20,
                child: _buildKeyButton(
                  label: '?123',
                  isAction: true,
                  onTap: () {
                    setState(() {
                      _isSymbolsPageActive = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Space key
              Expanded(
                flex: 50,
                child: _buildKeyButton(
                  label: 'Space',
                  isAction: false,
                  onTap: () => _onKeyTap(' '),
                ),
              ),
              const SizedBox(width: 4),
              // Done
              Expanded(
                flex: 30,
                child: _buildKeyButton(
                  label: 'Done',
                  isAction: true,
                  onTap: _onDoneTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolsKeyboard(bool obscureLabels) {
    // Symbol layout
    // Row 1: 1 2 3 4 5 6 7 8 9 0
    // Row 2: - / : ; ( ) $ & @ "
    // Row 3: ABC . , ? ! ' ⌫
    // Row 4: ABC [Space] Done
    final r1 = _symbolsPage1.sublist(0, 10);
    final r2 = _symbolsPage1.sublist(10, 20);
    final r3 = _symbolsPage1.sublist(20, 25);

    return Column(
      children: [
        // Row 1
        Expanded(
          child: Row(
            children: r1.map((char) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildKeyButton(
                    label: char,
                    isAction: false,
                    obscure: obscureLabels,
                    onTap: () => _onKeyTap(char),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Row 2
        Expanded(
          child: Row(
            children: r2.map((char) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildKeyButton(
                    label: char,
                    isAction: false,
                    obscure: obscureLabels,
                    onTap: () => _onKeyTap(char),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Row 3
        Expanded(
          child: Row(
            children: [
              // Switch back to ABC
              Expanded(
                flex: 18,
                child: _buildKeyButton(
                  label: 'ABC',
                  isAction: true,
                  onTap: () {
                    setState(() {
                      _isSymbolsPageActive = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              ...r3.map((char) {
                return Expanded(
                  flex: 11,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildKeyButton(
                      label: char,
                      isAction: false,
                      obscure: obscureLabels,
                      onTap: () => _onKeyTap(char),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // Backspace
              Expanded(
                flex: 18,
                child: _buildKeyButton(
                  label: '⌫',
                  isAction: true,
                  onTap: _onBackspaceTap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Row 4
        Expanded(
          child: Row(
            children: [
              // ABC switch
              Expanded(
                flex: 20,
                child: _buildKeyButton(
                  label: 'ABC',
                  isAction: true,
                  onTap: () {
                    setState(() {
                      _isSymbolsPageActive = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Space
              Expanded(
                flex: 50,
                child: _buildKeyButton(
                  label: 'Space',
                  isAction: false,
                  onTap: () => _onKeyTap(' '),
                ),
              ),
              const SizedBox(width: 4),
              // Done
              Expanded(
                flex: 30,
                child: _buildKeyButton(
                  label: 'Done',
                  isAction: true,
                  onTap: _onDoneTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.theme.headerBackgroundColor ?? widget.theme.backgroundColor,
        border: const Border(
          bottom: BorderSide(color: Colors.white10, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 14, color: Colors.cyanAccent),
              const SizedBox(width: 6),
              Text(
                widget.theme.headerText,
                style: widget.theme.headerTextStyle,
              ),
            ],
          ),
          TextButton(
            onPressed: _onDoneTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Done',
              style: widget.theme.actionTextStyle.copyWith(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildKeyButton({
    required String label,
    required bool isAction,
    bool obscure = false,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected
        ? Colors.cyanAccent.withOpacity(0.2)
        : (isAction
            ? widget.theme.actionKeyBackgroundColor
            : widget.theme.keyBackgroundColor);

    final String displayText = obscure ? '🔒' : label;

    return SecureKeyButton(
      onTap: onTap,
      backgroundColor: bgColor,
      borderRadius: widget.theme.keyBorderRadius,
      border: widget.theme.keyBorder,
      shadow: widget.theme.keyShadow,
      child: Center(
        child: Text(
          displayText,
          style: isAction ? widget.theme.actionTextStyle : widget.theme.textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A button that implements a subtle scale animation on tap.
class SecureKeyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? shadow;

  const SecureKeyButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.backgroundColor,
    required this.borderRadius,
    this.border,
    this.shadow,
  });

  @override
  State<SecureKeyButton> createState() => _SecureKeyButtonState();
}

class _SecureKeyButtonState extends State<SecureKeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border,
            boxShadow: widget.shadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
